# Policies and modes

The policy determines whether a matching rule permits or prohibits a statement. The mode determines whether sql_firewall learns rules, warns, or rejects statements.

| `sql_firewall.policy` | Matching SQL | Unmatched SQL |
| --- | --- | --- |
| `allowlist` (default) | Permitted | Policy violation |
| `denylist` | Policy violation | Permitted |

The policy applies to the entire cluster. Switching it requires a restart. Each policy's rules are saved separately.

| `sql_firewall.firewall` | Behavior |
| --- | --- |
| `disabled` | Skip policy checks and learning. |
| `learning` | Record statements as rules for the active policy. |
| `permissive` | Warn about a policy violation and continue execution. |
| `enforcing` | Reject a policy violation with an error. |

On PostgreSQL 18 and 19, ordinary SQL uses the server's 64-bit query IDs. Different literal values can produce the same ID. Use PostgreSQL privileges and row-level security for restrictions on particular rows or values. Utility commands such as DDL use a hash of the statement text, so formatting changes can produce a different rule. Design rules around the top-level statements sent by the client.

## Try the denylist

Use the temporary cluster after step 5 of the [Quickstart](quickstart.md). The commands below use the `admin` and `app` helpers from that guide to register the aggregate query on the denylist.

### 1. Learn the statement under the denylist policy

```sh
"$bindir/pg_ctl" -D "$demo/data" -m fast -w restart \
    -o '-c sql_firewall.policy=denylist'
admin -c "ALTER ROLE app_user SET sql_firewall.firewall = 'learning'"
app -Atc 'SELECT count(*) FROM demo_orders'
```

The query returns `2` and is added to the denylist for `app_user`. In denylist learning mode, run only the statements you intend to prohibit.

### 2. Observe the warning and rejection

```sh
admin -c "ALTER ROLE app_user SET sql_firewall.firewall = 'permissive'"
app -Atc 'SELECT count(*) FROM demo_orders'
```

The query emits a warning and returns `2`. Switch to `enforcing` and open new application connections.

```sh
admin -c "ALTER ROLE app_user SET sql_firewall.firewall = 'enforcing'"
app -Atc 'SELECT state FROM demo_orders WHERE id = 2'
app -Atc 'SELECT count(*) FROM demo_orders'
```

The lookup returns `pending`. The aggregate query fails with `ERROR:  Prohibited SQL statement`.

### 3. Switch back to the allowlist

```sh
"$bindir/pg_ctl" -D "$demo/data" -m fast -w restart \
    -o '-c sql_firewall.policy=allowlist'
app -Atc 'SELECT state FROM demo_orders WHERE id = 2'
```

The server loads the allowlist rules again, and the lookup returns `pending`.
