# Login role modes

A superuser can assign a login role its own default firewall mode. This lets you roll out `enforcing` for one application while another stays in `permissive` mode as you review its warnings and build its rules.

## Roll out enforcement for one application

Use `app_user` from the [Quickstart](quickstart.md). In an admin session, run the following command.

```sql
ALTER ROLE app_user SET sql_firewall.firewall = 'permissive';
```

Reconnect as `app_user` and check the mode and query result.

```sql
SHOW sql_firewall.firewall;
SELECT count(*) FROM demo_orders;
```

The mode is `permissive`. If the aggregate query has no rule in the allowlist, it emits a warning and returns `2`. After verifying that the application has learned the statements it needs, switch the role to `enforcing`.

```sql
ALTER ROLE app_user SET sql_firewall.firewall = 'enforcing';
```

Recycle existing connections in your connection pool to apply the new default. `SET ROLE` keeps the firewall mode already in effect for the session. The rule lookup uses the effective user ID when SQL runs.

## Restore the cluster default

```sql
ALTER ROLE app_user RESET sql_firewall.firewall;
```

The next connection uses the cluster default. A superuser can also put an individual maintenance connection in `disabled` mode. See [Promoting rules with CSV](rules.md) for an example.

An ordinary user without permission to set the parameter receives a permission error when attempting to change their firewall mode through `SET`, `ALTER ROLE`, or connection options.
