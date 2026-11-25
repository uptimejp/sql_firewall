# Shared temporary cluster for the role, policy, and rule-management tests.
# Source this file with PG_CONFIG set to the installation under test.
export LC_ALL=C
bindir=$("${PG_CONFIG:-pg_config}" --bindir)
work=$(mktemp -d)
data=$work/data
log=$work/server.log
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

"$bindir/initdb" -D "$data" -U "$dbuser" -A trust --no-locale >/dev/null
cat >> "$data/postgresql.conf" <<EOF
listen_addresses = ''
unix_socket_directories = '$work'
port = 5432
shared_preload_libraries = 'sql_firewall'
EOF

start()
{
    "$bindir/pg_ctl" -D "$data" -l "$log" -w start \
        -o "-c sql_firewall.firewall=$1 ${2-}" >/dev/null
}

stop()
{
    "$bindir/pg_ctl" -D "$data" -m fast -w stop >/dev/null
}

sql()
{
    "$bindir/psql" -XAt -v ON_ERROR_STOP=1 -h "$work" -p 5432 \
        -U "$1" -d postgres -c "$2"
}

expect_error()
{
    if output=$(sql "$1" "$2" 2>&1); then
        printf 'Expected an error for %s\n' "$2" >&2
        exit 1
    fi
    if ! printf '%s\n' "$output" | grep -F "$3" >/dev/null; then
        printf '%s\n' "$output" >&2
        exit 1
    fi
}
