%{!?pgmajor:%global pgmajor 18}
%{!?pg_config:%global pg_config /usr/pgsql-%{pgmajor}/bin/pg_config}

%if "%{pgmajor}" == "9.4"
%global pgsuffix 94
%else
%if "%{pgmajor}" == "18" || "%{pgmajor}" == "19"
%global pgsuffix %{pgmajor}
%else
%{error:pgmajor must be 9.4, 18, or 19}
%endif
%endif

Name:           postgresql%{pgsuffix}-sqlfirewall
Version:        0.8.1
Release:        1%{?dist}
Summary:        SQL Firewall extension for PostgreSQL
License:        PostgreSQL
URL:            https://github.com/soudai/sql_firewall
Source0:        sql_firewall-%{version}.tar.gz

BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  postgresql%{pgsuffix}-devel
Requires:       postgresql%{pgsuffix}-server

%description
sql_firewall is a PostgreSQL extension that learns SQL statement rules
and can warn about or reject statements according to those rules.

%prep
%setup -q -n sql_firewall-%{version}

%build
case "$(%{pg_config} --version)" in
    "PostgreSQL %{pgmajor}."*) ;;
    *) echo 'pg_config does not match pgmajor' >&2; exit 1 ;;
esac
%make_build USE_PGXS=1 PG_CONFIG=%{pg_config} with_llvm=no

%install
%make_install USE_PGXS=1 PG_CONFIG=%{pg_config} with_llvm=no

%files
%license COPYRIGHT
%doc README.md
%(%{pg_config} --pkglibdir)/sql_firewall.so
%(%{pg_config} --sharedir)/extension/sql_firewall.control
%(%{pg_config} --sharedir)/extension/sql_firewall--*.sql
