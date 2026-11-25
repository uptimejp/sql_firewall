# Quickstart

Set up a temporary cluster, learn a query that looks up one order, and observe how sql_firewall handles an unregistered aggregate query. Run the steps in the same Linux or WSL shell. [Install sql_firewall](installation.md) for the PostgreSQL version you plan to use first.

## 1. Start a temporary cluster

Run these commands as an unprivileged OS user. The cluster listens on a Unix socket in its own directory.

```sh
PG_CONFIG="${PG_CONFIG:-pg_config}"
bindir="$("$PG_CONFIG" --bindir)"
demo="$(mktemp -d /tmp/sqlfw-demo.XXXXXX)"
"$bindir/initdb" -D "$demo/data" -A trust --no-locale
cat >> "$demo/data/postgresql.conf" <<EOF
listen_addresses = ''
unix_socket_directories = '$demo'
port = 55432
shared_preload_libraries = 'sql_firewall'
sql_firewall.firewall = 'disabled'
EOF
"$bindir/pg_ctl" -D "$demo/data" -l "$demo/server.log" -w start

admin() {
    "$bindir/psql" -X -v ON_ERROR_STOP=1 -h "$demo" -p 55432 \
        -U "$(id -un)" -d postgres "$@"
}
app() {
    "$bindir/psql" -X -v ON_ERROR_STOP=1 -h "$demo" -p 55432 \
        -U app_user -d postgres "$@"
}
```

## 2. Set up the application role

```sh
admin <<'SQL'
CREATE EXTENSION sql_firewall;
CREATE ROLE app_user LOGIN;
CREATE TABLE demo_orders (id integer PRIMARY KEY, state text NOT NULL);
INSERT INTO demo_orders VALUES (1, 'paid'), (2, 'pending');
GRANT SELECT ON demo_orders TO app_user;
ALTER ROLE app_user SET sql_firewall.firewall = 'learning';
SQL
```

## 3. Learn the order lookup

```sh
app -Atc 'SELECT state FROM demo_orders WHERE id = 1'
app -Atc 'SELECT state FROM demo_orders WHERE id = 2'
```

The queries return `paid` and `pending`. They differ only in the constants `1` and `2`, so they produce one rule in this example. Inspect the normalized SQL and verify that `calls` is `2`.

```sh
admin -c "
SELECT query, calls
FROM sql_firewall.sql_firewall_statements
WHERE userid = (SELECT oid FROM pg_roles WHERE rolname = 'app_user');"
```

## 4. Warn about the unregistered aggregate query

```sh
admin -c "ALTER ROLE app_user SET sql_firewall.firewall = 'permissive'"
app -Atc 'SELECT count(*) FROM demo_orders'
```

```text
WARNING:  Prohibited SQL statement
2
```

## 5. Reject the unregistered aggregate query

```sh
admin -c "ALTER ROLE app_user SET sql_firewall.firewall = 'enforcing'"
app -Atc 'SELECT state FROM demo_orders WHERE id = 2'
app -Atc 'SELECT count(*) FROM demo_orders'
```

The lookup returns `pending`. The aggregate query fails with `ERROR:  Prohibited SQL statement` because only `learning` mode adds new rules.

```sh
admin -Atc 'SELECT sql_warning, sql_error FROM sql_firewall.sql_firewall_stat'
```

If you followed only these steps, the result is `1|1`.

## 6. Stop the temporary cluster

Leave the cluster running if you want to try the [denylist walkthrough](policies.md). To finish the tutorial, run the following command.

```sh
"$bindir/pg_ctl" -D "$demo/data" -m fast -w stop
```

After shutdown, you can remove the temporary directory identified by `$demo` if you no longer need the data.
