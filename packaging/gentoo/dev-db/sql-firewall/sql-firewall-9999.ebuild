# Distributed under the terms of the GNU General Public License v2

EAPI=8

POSTGRES_COMPAT=( 9.4 18 19 )
inherit git-r3 postgres-multi

DESCRIPTION="SQL Firewall extension for PostgreSQL"
HOMEPAGE="https://github.com/soudai/sql_firewall"
EGIT_REPO_URI="https://github.com/soudai/sql_firewall.git"
EGIT_BRANCH="main"

LICENSE="POSTGRESQL"
SLOT="0"
REQUIRED_USE="${POSTGRES_REQ_USE}"
RESTRICT="test"

RDEPEND="${POSTGRES_DEP}"
DEPEND="${RDEPEND}"

sql_firewall_make() {
	emake USE_PGXS=1 PG_CONFIG="${PG_CONFIG}" "$@"
}

src_compile() {
	postgres-multi_foreach sql_firewall_make all
}

sql_firewall_install() {
	sql_firewall_make DESTDIR="${D}" install
}

src_install() {
	postgres-multi_foreach sql_firewall_install
	dodoc README.md ChangeLog
}
