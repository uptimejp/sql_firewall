# sql_firewall

## Overview

sql_firewall is a PostgreSQL extension which is intended to protect
database from SQL injections or unexpected queries.

sql_firewall learns statement rules and can warn about or reject SQL
according to the selected rule policy.

## How it works

Rules are keyed by `userid` and `queryid`. The default `allowlist`
policy prohibits statements missing from the rule table for the user.
The `denylist` policy prohibits statements present in that table.

| Mode | Behavior |
| --- | --- |
| `learning` | Collect statements as rules for the selected policy. |
| `permissive` | Execute statements and warn when the policy prohibits them. |
| `enforcing` | Reject statements that the policy prohibits before they execute. |
| `disabled` | Skip policy checks and rule learning. |

## Compatibility

sql_firewall supports PostgreSQL 9.4.x, 18.x and 19.x.

On PostgreSQL 18 and 19, SQL statements use PostgreSQL's 64-bit query IDs.
Utility statements use a hash of the individual statement text.
Relearn rules in the destination cluster after a major-version upgrade.
Rule IDs in saved or exported rules are specific to the PostgreSQL major
version and may also depend on object OIDs.

## Installation

sql_firewall can be built as a PostgreSQL extension.

```sh
export PATH=$PGHOME/bin:$PATH
export USE_PGXS=1
make
sudo make install
```

On PostgreSQL 18 or 19, run the smoke test as an unprivileged OS user
after installing sql_firewall and pg_stat_statements for that version.

```sh
PG_CONFIG=$PGHOME/bin/pg_config sh tests/smoke.sh
```

See [Building an RPM](packaging/rpm/README.md) for the PGDG package recipe.
See the [Gentoo overlay recipe](packaging/gentoo/README.md) for Portage.

## Configuration

Set these values in `postgresql.conf`.

```conf
shared_preload_libraries = 'sql_firewall'
sql_firewall.firewall = 'learning'
```

Restart PostgreSQL and create the extension in the desired database.

```sh
pg_ctl -D "$PGDATA" restart
psql mydb -c 'CREATE EXTENSION sql_firewall'
```

sql_firewall would check all queries incoming to not only the specific
database where the module is installed, but all the databases in the
entire PostgreSQL cluster.

Even though, the views and functions in the module would be available
only on the installed database.

## GUC Parameters

- `shared_preload_libraries`

  sql_firewall module needs to be loaded in the
  shared_preload_libraries parameter as shown below.

  ```conf
  shared_preload_libraries = 'sql_firewall'
  ```

  On PostgreSQL 18 and 19, sql_firewall and pg_stat_statements can be
  preloaded in either order. Both use the query ID computed by PostgreSQL.

  On PostgreSQL 9.4, preload pg_stat_statements first to avoid an assertion
  failure in pg_stat_statements builds with assertion checking enabled.

  ```conf
  shared_preload_libraries = 'pg_stat_statements,sql_firewall'
  ```

- `compute_query_id` (PostgreSQL 18 and 19)

  Keep the default setting of 'auto', or explicitly set it to 'on'.
  With SQL Firewall active and compute_query_id set to 'off', queries
  requiring a query ID are rejected with a configuration error.

- `sql_firewall.firewall`

  sql_firewall.firewall is able to take one of the following values:
  'disabled', 'learning', 'permissive' and 'enforcing'.
  The default value is 'disabled'.

  A superuser can override the server default for a login role or for
  an administrative session.

  ```sql
  ALTER ROLE app_user SET sql_firewall.firewall = 'enforcing';
  ALTER ROLE app_user RESET sql_firewall.firewall;
  ```

  Role defaults apply to new connections. `SET ROLE` retains the
  session's current mode. All sessions share the rule table, and the
  rules learned by a login role are saved on a clean server shutdown.

- `sql_firewall.policy`

  The default is `allowlist`. Set `sql_firewall.policy = 'denylist'` in
  `postgresql.conf` and restart to use a denylist. The server loads and saves
  each policy's rules separately. In denylist learning mode, run only the
  statements you intend to prohibit for the corresponding login roles.
  CSV exports contain rule rows for the active policy, so use a matching
  policy when importing a rule file.

- `sql_firewall.max`

  Number of queries the SQL Firewall can learn.
  It can take an int value between 100 and INT_MAX.
  The default value is 5000.
  The queries which exceed this value in the "learning" mode would never
  be learned.

## Functions

- `sql_firewall_reset()`

  sql_firewall_reset() clears the firewall rules.

  This function is available only under the disabled mode with
  superuser privilege.

- `sql_firewall_stat_reset()`

  sql_firewall_stat_reset() clears the counters of warning and error. Only
  available with superuser privilege.

- `sql_firewall_export_rule('/path/to/rule.txt')`

  sql_firewall_export_rule() writes the firewall rules in the
  specified CSV file.

  This function is available only under the disabled mode with
  superuser privilege.

- `sql_firewall_import_rule('/path/to/rule.txt')`

  sql_firewall_import_rule() reads the firewall rules from the
  specified CSV file.

  This function is available only under the disabled mode with
  superuser privilege.

## Views

- `sql_firewall.sql_firewall_statements`

  sql_firewall_statements view shows the firewall rules and execution
  counter for each query.

  ```text
  postgres=# select * from sql_firewall.sql_firewall_statements;
   userid |  queryid   |              query              | calls
  --------+------------+---------------------------------+-------
       10 | 3294787656 | select * from k1 where uid = ?; |     4
  (1 row)

  postgres=#
  ```

- `sql_firewall.sql_firewall_stat`

  sql_firewall_stat view has two counters: "sql_warning" and
  "sql_error".

  "sql_warning" shows number of executed queries with warnings in the
  "permissive" mode.

  "sql_error" shows number of prevented queries in the "enforcing"
  mode.

  ```text
  postgres=# select * from sql_firewall.sql_firewall_stat;
   sql_warning | sql_error
  -------------+-----------
             2 |         1
  (1 row)

  postgres=#
  ```

## Examples

- Permissive mode

  ```text
  postgres=# select * from sql_firewall.sql_firewall_statements;
  WARNING:  Prohibited SQL statement
   userid |  queryid   |              query              | calls
  --------+------------+---------------------------------+-------
       10 | 3294787656 | select * from k1 where uid = 1; |     1
  (1 row)

  postgres=# select * from k1 where uid = 1;
   uid |    uname
  -----+-------------
     1 | Park Gyu-ri
  (1 row)

  postgres=# select * from k1 where uid = 3;
   uid |   uname
  -----+-----------
     3 | Goo Ha-ra
  (1 row)

  postgres=# select * from k1 where uid = 3 or 1 = 1;
  WARNING:  Prohibited SQL statement
   uid |     uname
  -----+----------------
     1 | Park Gyu-ri
     2 | Nicole Jung
     3 | Goo Ha-ra
     4 | Han Seung-yeon
     5 | Kang Ji-young
  (5 rows)

  postgres=#
  ```

- Enforcing mode

  ```text
  postgres=# select * from k1 where uid = 3;
   uid |   uname
  -----+-----------
     3 | Goo Ha-ra
  (1 row)

  postgres=# select * from k1 where uid = 3 or 1 = 1;
  ERROR:  Prohibited SQL statement
  postgres=#
  ```

## Authors

Satoshi Nagayasu <snaga@uptime.jp>
