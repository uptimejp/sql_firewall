# Package installation

The fork includes an RPM spec for PGDG installations and an ebuild for a Gentoo overlay.

## RPM

Install the matching PGDG PostgreSQL development package, a C compiler, GNU Make, and `rpmbuild`. For PostgreSQL 19, use `postgresql19-devel`. The spec accepts `9.4`, `18`, and `19` as `pgmajor`. The 9.4 build requires the archived development package.

```sh
topdir="$(rpm --eval '%{_topdir}')"
mkdir -p "$topdir/SOURCES"
git archive --format=tar.gz --prefix=sql_firewall-0.8.1/ \
    -o "$topdir/SOURCES/sql_firewall-0.8.1.tar.gz" HEAD
rpmbuild -ba --define 'pgmajor 19' packaging/rpm/sql_firewall.spec
```

Find the binary packages in `$topdir/RPMS`. Use `rpm -qpl` to confirm that the package contains the module, SQL script, and control file, then install the desired RPM.

```sh
sudo dnf install /path/to/generated-postgresql19-sqlfirewall.rpm
```

For a custom PostgreSQL installation, pass `--define 'pg_config /path/to/bin/pg_config'`. The build verifies that `pg_config` matches `pgmajor`. [RPM spec and build instructions](https://github.com/soudai/sql_firewall/tree/main/packaging/rpm)

## Gentoo

Copy the [ebuild directory](https://github.com/soudai/sql_firewall/tree/main/packaging/gentoo/dev-db/sql-firewall) to `dev-db/sql-firewall` in a local overlay. The ebuild builds the fork's `main` branch.

To target PostgreSQL 18, for example, add this entry to Portage's `package.use`.

```text
dev-db/sql-firewall postgres_targets_postgres18
```

```sh
ebuild /path/to/overlay/dev-db/sql-firewall/sql-firewall-9999.ebuild manifest
emerge --ask dev-db/sql-firewall
```

Available PostgreSQL slots depend on the Gentoo repositories and `postgres-multi` eclass in use. [Gentoo overlay instructions](https://github.com/soudai/sql_firewall/tree/main/packaging/gentoo)

After installing a package, [preload the module and create the extension](installation.md).
