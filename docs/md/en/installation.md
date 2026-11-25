# Installation

Build the extension with the `pg_config` and server headers for the PostgreSQL major version that will run it. Supported versions are **9.4.x, 18.x, and 19.x**. See [Package installation](packaging.md) for the RPM and Gentoo recipes.

## 1. Build and install

Use Git, a C compiler, and GNU Make on Linux or WSL. If PostgreSQL came from a package, install the development package for the target version as well.

```sh
git clone --branch main https://github.com/soudai/sql_firewall.git
cd sql_firewall

export PG_CONFIG="$(command -v pg_config)"
"$PG_CONFIG" --version
"$PG_CONFIG" --pgxs
make USE_PGXS=1 PG_CONFIG="$PG_CONFIG"
sudo make USE_PGXS=1 PG_CONFIG="$PG_CONFIG" install
```

If you have multiple PostgreSQL installations, set `PG_CONFIG` to the absolute path for the target installation. You can omit `sudo` if your OS user can write to the installation directories. [PostgreSQL PGXS documentation](https://www.postgresql.org/docs/19/extend-pgxs.html)

## 2. Preload the module

Edit `postgresql.conf` for the target cluster. Append `sql_firewall` to the existing list if `shared_preload_libraries` already contains other libraries. Start in `disabled` mode so you can prepare application connections before learning rules.

```conf
shared_preload_libraries = 'sql_firewall'
sql_firewall.firewall = 'disabled'
```

On PostgreSQL 18 and 19, leave `compute_query_id` at its default of `auto` or set it to `on`. Both preload orders were tested with `pg_stat_statements` on 18 and 19. On 9.4, put `pg_stat_statements` first.

Restart the cluster to apply the preload setting. Use the service manager for a managed service, or use `pg_ctl` for a cluster that you started manually.

```sh
"$("$PG_CONFIG" --bindir)/pg_ctl" -D "$PGDATA" -w restart
```

## 3. Create the extension and verify the setup

Connect as a superuser to the database where you want to use the functions and views.

```sql
CREATE EXTENSION sql_firewall;
SHOW shared_preload_libraries;
SHOW sql_firewall.firewall;
SELECT sql_warning, sql_error FROM sql_firewall.sql_firewall_stat;
```

The preload list should include `sql_firewall` and the mode should be `disabled`. Rules and enforcement apply across the cluster. The management functions and views are available in databases where you create the extension.

Continue with the [Quickstart](quickstart.md) to try learning, warning, and enforcement in a temporary cluster.
