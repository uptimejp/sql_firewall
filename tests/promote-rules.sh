#!/bin/sh
set -eu
. "$(dirname "$0")/test-cluster.sh"

start disabled
sql "$dbuser" 'CREATE EXTENSION sql_firewall'
sql "$dbuser" 'CREATE ROLE fw_app LOGIN'
sql "$dbuser" 'CREATE TABLE demo (i int); INSERT INTO demo VALUES (1), (2)'
sql "$dbuser" 'GRANT SELECT ON demo TO fw_app'
stop

# Copy the stopped cluster so staging and production have the same OIDs.
production=$work/production
cp -R "$data" "$production"
query='SELECT i AS "item",
       i + 1 FROM demo WHERE i = 1'

start learning
[ "$(sql fw_app "$query")" = '1|2' ]
[ "$(PGOPTIONS='-c sql_firewall.firewall=disabled' \
    sql "$dbuser" "SELECT sql_firewall_export_rule('$work/rules.csv')")" = t ]
stop

data=$production
start enforcing '-c sql_firewall.max=100'
expect_error fw_app "$query" 'Prohibited SQL statement'
cp "$work/rules.csv" "$work/invalid.csv"
printf 'incomplete record\n' >> "$work/invalid.csv"
PGOPTIONS='-c sql_firewall.firewall=disabled' expect_error "$dbuser" \
    "SELECT sql_firewall_import_rule('$work/invalid.csv')" 'invalid SQL firewall CSV record 2'
expect_error fw_app "$query" 'Prohibited SQL statement'

app_oid=$(PGOPTIONS='-c sql_firewall.firewall=disabled' \
    sql "$dbuser" "SELECT oid FROM pg_roles WHERE rolname = 'fw_app'")
cp "$work/rules.csv" "$work/oversized.csv"
awk -v userid="$app_oid" 'BEGIN {
    for (i = 1; i <= 101; i++)
        print userid "," i ",SELECT 1,1"
}' >> "$work/oversized.csv"
PGOPTIONS='-c sql_firewall.firewall=disabled' expect_error "$dbuser" \
    "SELECT sql_firewall_import_rule('$work/oversized.csv')" 'rule import would exceed sql_firewall.max'
expect_error fw_app "$query" 'Prohibited SQL statement'

[ "$(PGOPTIONS='-c sql_firewall.firewall=disabled' \
    sql "$dbuser" "SELECT sql_firewall_import_rule('$work/rules.csv')")" = t ]
[ "$(sql fw_app "$query")" = '1|2' ]
expect_error fw_app 'SELECT count(*) FROM demo' 'Prohibited SQL statement'
[ "$(PGOPTIONS='-c sql_firewall.firewall=disabled' \
    sql "$dbuser" "SELECT sql_firewall_import_rule('$work/rules.csv')")" = t ]
[ "$(PGOPTIONS='-c sql_firewall.firewall=disabled' sql "$dbuser" \
    "SELECT calls FROM sql_firewall.sql_firewall_statements
     WHERE userid = (SELECT oid FROM pg_roles WHERE rolname = 'fw_app')")" = 2 ]
stop

start enforcing
[ "$(sql fw_app "$query")" = '1|2' ]
expect_error fw_app 'SELECT count(*) FROM demo' 'Prohibited SQL statement'
stop

printf 'Rule promotion test passed on %s\n' "$("$bindir/postgres" --version)"
