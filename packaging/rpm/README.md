# Building an RPM

Install RPM build tools, a C compiler, GNU Make, and the matching PGDG
PostgreSQL development package. The spec uses the PGDG directory layout.
It defaults to PostgreSQL 18 and accepts `pgmajor` values `9.4`, `18`,
and `19`. Building for 9.4 requires its archived development package.

From the repository root, archive the committed revision you want to package
and build it with the matching PostgreSQL major version.

```sh
topdir=$(rpm --eval '%{_topdir}')
mkdir -p "$topdir/SOURCES"
git archive --format=tar.gz --prefix=sql_firewall-0.8.1/ \
    -o "$topdir/SOURCES/sql_firewall-0.8.1.tar.gz" HEAD
rpmbuild -ba --define 'pgmajor 19' packaging/rpm/sql_firewall.spec
```

For a custom PostgreSQL location, also pass
`--define 'pg_config /path/to/bin/pg_config'`. The build checks that the
selected `pg_config` belongs to the specified major version.
