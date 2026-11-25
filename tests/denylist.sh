#!/bin/sh
set -eu
. "$(dirname "$0")/test-cluster.sh"

start disabled
sql "$dbuser" 'CREATE EXTENSION sql_firewall'
sql "$dbuser" 'CREATE ROLE fw_other LOGIN'
sql "$dbuser" 'CREATE SEQUENCE probe'
sql "$dbuser" 'GRANT USAGE ON SEQUENCE probe TO fw_other'
stop

start learning
[ "$(sql "$dbuser" 'SELECT 42')" = 42 ]
stop

denylist='-c sql_firewall.policy=denylist'
start learning "$denylist"
[ "$(sql "$dbuser" "SELECT nextval('probe')")" = 1 ]
sql "$dbuser" 'CREATE TEMP TABLE blocked (i int)'
stop

start permissive "$denylist"
output=$(sql "$dbuser" "SELECT nextval('probe')" 2>&1)
printf '%s\n' "$output" | grep -F 'WARNING:  Prohibited SQL statement' >/dev/null
[ "$(printf '%s\n' "$output" | tail -n 1)" = 2 ]
stop

start enforcing "$denylist"
[ "$(sql "$dbuser" 'SELECT 42')" = 42 ]
expect_error "$dbuser" "SELECT nextval('probe')" 'Prohibited SQL statement'
expect_error "$dbuser" 'CREATE TEMP TABLE blocked (i int)' 'Prohibited SQL statement'
[ "$(sql "$dbuser" 'SELECT last_value FROM probe')" = 2 ]
[ "$(sql fw_other "SELECT nextval('probe')")" = 3 ]
[ "$(sql "$dbuser" 'SELECT sql_warning, sql_error FROM sql_firewall.sql_firewall_stat')" = '1|2' ]
stop

start enforcing
[ "$(sql "$dbuser" 'SELECT 42')" = 42 ]
expect_error "$dbuser" "SELECT nextval('probe')" 'Prohibited SQL statement'
stop

printf 'Denylist test passed on %s\n' "$("$bindir/postgres" --version)"
