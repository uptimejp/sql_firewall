# Reference and troubleshooting

## Configuration parameters

| Parameter | Default | Where it applies |
| --- | --- | --- |
| `shared_preload_libraries` | PostgreSQL setting | Add `sql_firewall` and restart the cluster. |
| `sql_firewall.firewall` | `disabled` | Cluster default, login role default, or superuser session. Modes are `disabled`, `learning`, `permissive`, and `enforcing`. |
| `sql_firewall.policy` | `allowlist` | Cluster-wide. Switching to `denylist` requires a restart. |
| `sql_firewall.max` | `5000` | Maximum number of rules in the cluster. The minimum is `100`. Restart after changing it. |
| `compute_query_id` (18 and 19) | `auto` | Use `auto` or `on` to compute query IDs. |

## Inspect rules and counters

Run these queries from an admin session in the database where you created the extension. If the cluster default is `enforcing`, you can use `disabled` for the individual maintenance connection.

```sql
SELECT userid, queryid, query, calls
FROM sql_firewall.sql_firewall_statements
ORDER BY calls DESC, userid, queryid
LIMIT 10;

SELECT sql_warning, sql_error
FROM sql_firewall.sql_firewall_stat;
```

`calls` is the execution count recorded for a rule. `sql_warning` counts warnings in `permissive` mode. `sql_error` counts rejections in `enforcing` mode. The cluster shares these counters across sessions.

## Management functions

| Function | What it does | Requirements |
| --- | --- | --- |
| `sql_firewall_export_rule(text)` | Export the active policy's rules to a server-side CSV file. | Superuser session in `disabled` mode. |
| `sql_firewall_import_rule(text)` | Add rules from a server-side CSV file. | Superuser session in `disabled` mode. |
| `sql_firewall_stat_reset()` | Reset the warning and error counters. | Superuser. |
| `sql_firewall_reset()` | Clear all rules for the active policy. | Superuser session in `disabled` mode. |

To reset the warning and error counters on a temporary cluster, run the following commands.

```sql
SELECT sql_firewall_stat_reset();
SELECT sql_warning, sql_error FROM sql_firewall.sql_firewall_stat;
```

If no other sessions raise warnings or rejections at the same time, the result is `0 | 0`.

To clear all rules for the active policy on a temporary cluster, use a superuser session in `disabled` mode.

```sql
SELECT sql_firewall_reset();
SELECT count(*) FROM sql_firewall.sql_firewall_statements;
```

If no rules are learned or imported concurrently, the count is `0`. This clears rules across the cluster. [Export the rules to CSV](rules.md) first if you need to restore them later.

## Common errors

| Symptom | What to check |
| --- | --- |
| `sql_firewall must be loaded via shared_preload_libraries` | Add the module to the preload list and restart the correct cluster. |
| `could not access file "sql_firewall"` | Check that you built and installed with the target server's `pg_config`. |
| `sql_firewall requires compute_query_id to be auto or on` | Check that PostgreSQL 18 or 19 uses `auto` or `on`. |
| An expected query gets `Prohibited SQL statement` | Check the connection role, active policy and mode, query ID, and whether the DDL text matches what was learned. |
| A role's mode did not change | Open a new connection after running `ALTER ROLE`. |
| Rules no longer match after moving a CSV | Compare the PostgreSQL major version, policy, role OIDs, and object OIDs across both environments. |
