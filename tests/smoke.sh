#!/bin/sh
# Run with sql_firewall and pg_stat_statements installed, as an unprivileged
# OS user. Set PG_CONFIG to select the PostgreSQL installation.
set -eu

bindir=$("${PG_CONFIG:-pg_config}" --bindir)
work=$(mktemp -d)
data=$work/data
log=$work/server.log
port=5432
dbuser=$(id -un)

cleanup()
{
    status=$?
    "$bindir/pg_ctl" -D "$data" -m immediate stop >/dev/null 2>&1 || true
    if [ "$status" -ne 0 ] && [ -f "$log" ]; then
        cat "$log" >&2
    fi
    rm -rf -- "$work"
}
trap cleanup EXIT

sql()
{
    "$bindir/psql" -XAt -v ON_ERROR_STOP=1 -h "$work" -p "$port" \
        -U "$dbuser" -d postgres -c "$1"
}

start()
{
    "$bindir/pg_ctl" -D "$data" -l "$log" -w start \
        -o "-c sql_firewall.firewall=$1" >/dev/null
}

stop()
{
    "$bindir/pg_ctl" -D "$data" -m fast -w stop >/dev/null
}

expect_error()
{
    if output=$(sql "$1" 2>&1); then
        printf 'Expected an error for %s\n' "$1" >&2
        exit 1
    fi
    printf '%s\n' "$output" | grep -F "$2" >/dev/null
}

"$bindir/initdb" -D "$data" -U "$dbuser" -A trust --no-locale >/dev/null
cat >> "$data/postgresql.conf" <<EOF
listen_addresses = ''
unix_socket_directories = '$work'
port = $port
shared_preload_libraries = '${PRELOAD_LIBRARIES:-sql_firewall,pg_stat_statements}'
EOF

start learning
sql 'CREATE EXTENSION sql_firewall; CREATE EXTENSION pg_stat_statements'
sql 'CREATE TABLE demo (i int); INSERT INTO demo VALUES (1), (2)'
sql 'CREATE SEQUENCE probe'
sql 'CREATE TEMP TABLE allowed (i int)'
[ "$(sql 'SELECT i FROM demo WHERE i = 1')" = 1 ]
[ "$(sql 'SELECT i FROM demo WHERE i = 2')" = 2 ]
[ "$(sql 'SELECT i FROM demo WHERE i = 1; SELECT i FROM demo WHERE i = 2')" = "$(printf '1\n2')" ]
[ "$(sql 'PREPARE find(int) AS SELECT i FROM demo WHERE i = $1; EXECUTE find(1)')" = "$(printf 'PREPARE\n1')" ]
[ "$(sql "SELECT count(*) FROM sql_firewall.sql_firewall_statements WHERE query = 'SELECT i FROM demo WHERE i = ?' AND calls = 4 AND abs(queryid::numeric) > 4294967295")" = 1 ]
[ "$(sql 'SELECT i FROM demo WHERE i IN (1, 2) ORDER BY i')" = "$(printf '1\n2')" ]
[ "$(sql "SELECT count(*) FROM sql_firewall.sql_firewall_statements WHERE query = 'SELECT i FROM demo WHERE i IN (?) ORDER BY i' AND calls = 1")" = 1 ]
sql 'SELECT sql_warning, sql_error FROM sql_firewall.sql_firewall_stat'
stop

start permissive
output=$(sql 'SELECT count(*) FROM demo' 2>&1)
printf '%s\n' "$output" | grep -F 'WARNING:  Prohibited SQL statement' >/dev/null
[ "$(printf '%s\n' "$output" | tail -n 1)" = 2 ]
[ "$(sql 'SELECT sql_warning, sql_error FROM sql_firewall.sql_firewall_stat')" = '1|0' ]
stop

start disabled
sql "SELECT sql_firewall_export_rule('$work/rules.csv')"
sql 'SELECT sql_firewall_reset()'
sql "SELECT sql_firewall_import_rule('$work/rules.csv')"
stop

start enforcing
[ "$(sql 'SELECT i FROM demo WHERE i = 2')" = 2 ]
[ "$(sql 'SELECT i FROM demo WHERE i = 1; SELECT i FROM demo WHERE i = 2')" = "$(printf '1\n2')" ]
[ "$(sql 'PREPARE find(int) AS SELECT i FROM demo WHERE i = $1; EXECUTE find(2)')" = "$(printf 'PREPARE\n2')" ]
sql 'CREATE TEMP TABLE allowed (i int)'
expect_error 'SELECT count(*) FROM demo' 'Prohibited SQL statement'
expect_error "SELECT nextval('probe')" 'Prohibited SQL statement'
expect_error 'CREATE TABLE rejected (i int)' 'Prohibited SQL statement'
[ "$(sql 'SELECT sql_warning, sql_error FROM sql_firewall.sql_firewall_stat')" = '1|3' ]
PGOPTIONS='-c compute_query_id=off' expect_error \
    'SELECT i FROM demo WHERE i = 2' 'sql_firewall requires compute_query_id to be auto or on'
stop

start disabled
[ "$(sql 'SELECT is_called FROM probe')" = f ]
[ "$(sql "SELECT to_regclass('rejected') IS NULL")" = t ]
stop

printf 'sql_firewall smoke test passed for %s\n' "$("$bindir/postgres" --version)"
