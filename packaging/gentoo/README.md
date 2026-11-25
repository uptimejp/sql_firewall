# Gentoo overlay

Copy the [ebuild directory](dev-db/sql-firewall) to
`dev-db/sql-firewall` in a local Gentoo overlay and generate its Manifest
with the `ebuild ... manifest` command. This live ebuild builds the
fork's `main` branch.

Set `POSTGRES_TARGETS` to the PostgreSQL slots you want to build against,
then emerge `dev-db/sql-firewall`. The recipe declares the extension's
supported versions (9.4, 18 and 19). Portage selects slots recognized by
the installed `postgres-multi` eclass and available in your Gentoo
repositories.
