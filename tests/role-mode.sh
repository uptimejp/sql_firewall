#!/bin/sh
set -eu
. "$(dirname "$0")/test-cluster.sh"

start disabled
sql "$dbuser" 'CREATE EXTENSION sql_firewall'
sql "$dbuser" "CREATE ROLE fw_learner LOGIN; CREATE ROLE fw_exempt LOGIN; CREATE ROLE fw_default LOGIN"
sql "$dbuser" "ALTER ROLE fw_learner SET sql_firewall.firewall = 'learning'"
sql "$dbuser" "ALTER ROLE fw_exempt SET sql_firewall.firewall = 'disabled'"
[ "$(sql fw_learner 'SHOW sql_firewall.firewall')" = learning ]
[ "$(sql fw_learner 'SELECT 42')" = 42 ]
[ "$(sql fw_default 'SHOW sql_firewall.firewall')" = disabled ]
stop

start enforcing
PGOPTIONS='-c sql_firewall.firewall=disabled' \
    sql "$dbuser" 'ALTER ROLE fw_learner RESET sql_firewall.firewall'
[ "$(sql fw_learner 'SELECT 42')" = 42 ]
expect_error fw_default 'SELECT 42' 'Prohibited SQL statement'
[ "$(sql fw_exempt 'SELECT 42')" = 42 ]
expect_error fw_exempt 'SET sql_firewall.firewall = learning' 'permission denied'
expect_error fw_exempt \
    "ALTER ROLE fw_exempt SET sql_firewall.firewall = 'learning'" 'permission denied'
PGOPTIONS='-c sql_firewall.firewall=learning' \
    expect_error fw_exempt 'SELECT 42' 'permission denied'
stop

printf 'Role mode test passed on %s\n' "$("$bindir/postgres" --version)"
