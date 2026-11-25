# Promoting rules with CSV

Learn allowlist rules in staging, then add them to production while application connections remain in `enforcing` mode. Use `disabled` for the superuser connection that runs the export or import.

## 1. Prepare environments with matching rule IDs

Use the same PostgreSQL major version and `sql_firewall.policy` in both environments. The CSV keys are role OIDs and query IDs. Query IDs can depend on the OIDs of referenced objects, so rebuilding a database from the same names can produce different rule IDs. Learning on a physical copy of the target cluster preserves those OIDs. Relearn rules on the target version when upgrading across PostgreSQL major versions.

In this example, `STAGING_ADMIN_DSN` and `PROD_ADMIN_DSN` specify superuser connections. `STAGING_APP_DSN` and `PROD_APP_DSN` use the same application role in each environment. The example uses `demo_orders` from the [Quickstart](quickstart.md).

## 2. Learn and export in staging

```sh
PGOPTIONS='-c sql_firewall.firewall=disabled' \
    psql "$STAGING_ADMIN_DSN" -X -v ON_ERROR_STOP=1 \
    -c "ALTER ROLE app_user SET sql_firewall.firewall = 'learning'"

psql "$STAGING_APP_DSN" -X -v ON_ERROR_STOP=1 \
    -c 'SELECT state FROM demo_orders WHERE id = 1'

PGOPTIONS='-c sql_firewall.firewall=disabled' \
    psql "$STAGING_ADMIN_DSN" -X -At -v ON_ERROR_STOP=1 \
    -c "SELECT sql_firewall_export_rule('/path/to/firewall.csv')"
```

The export returns `t` and writes the file on the **staging PostgreSQL server**.

## 3. Import while production enforcement stays active

Copy the CSV to the production server and place it where the PostgreSQL server process can read it. Keep the application role in `enforcing` mode.

```sh
PGOPTIONS='-c sql_firewall.firewall=disabled' \
    psql "$PROD_ADMIN_DSN" -X -At -v ON_ERROR_STOP=1 \
    -c "SELECT sql_firewall_import_rule('/path/to/firewall.csv')"
```

A result of `t` means the new rule snapshot was written to disk. A result of `f` means the rules were added in memory and the snapshot write failed. Check the server log for the file error, fix it, and import the same CSV again.

If the CSV is invalid or the import would exceed `sql_firewall.max`, the import raises an error before adding rules. Reimporting preserves existing rules and execution counters.

## 4. Verify from the application connection

```sh
psql "$PROD_APP_DSN" -X -At -v ON_ERROR_STOP=1 \
    -c 'SELECT state FROM demo_orders WHERE id = 1'
psql "$PROD_APP_DSN" -X -At -v ON_ERROR_STOP=1 \
    -c 'SELECT count(*) FROM demo_orders'
```

The lookup returns `paid`. If the aggregate query was already absent from the production allowlist, it still fails with `ERROR:  Prohibited SQL statement`. See [tests/promote-rules.sh](https://github.com/soudai/sql_firewall/blob/main/tests/promote-rules.sh) for the integration test.
