%define pgversion 94
%define _PGHOME /usr/pgsql-9.4

Name: postgresql%{pgversion}-sqlfirewall
Summary: SQL Firewall Extension for PostgreSQL
Version: 0.8
Release: 1%{?dist}

Group: Applications/Databases
License: PostgreSQL License

URL: https://github.com/uptimejp/sql_firewall
Source0: sql_firewall-0_8.zip

BuildRoot: %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildRequires: postgresql%{pgversion}-devel

Requires: postgresql%{pgversion}
Requires: postgresql%{pgversion}-contrib
Requires: postgresql%{pgversion}-libs
Requires: postgresql%{pgversion}-server

%description
sql_firewall is a PostgreSQL extension which is intended to protect
database from SQL injections or unexpected queries.

%prep
%setup -q -n sql_firewall-0_8

%build
export PATH=%{_PGHOME}/bin:$PATH
%{__make} USE_PGXS=1 all

%install
%{__rm} -rf %{buildroot}

export PATH=%{_PGHOME}/bin:$PATH

mkdir -p %{buildroot}%{_PGHOME}/bin %{buildroot}%{_PGHOME}/share/extension

%{__make} USE_PGXS=1 DESTDIR=%{buildroot} PREFIX=%{_prefix} install

%clean
%{__rm} -rf %{buildroot}

%pre

%post

%preun

%postun

%files
%defattr(-,root,root,-)
%doc README.sql_firewall
%{_PGHOME}/share/extension/sql_firewall.control
%{_PGHOME}/share/extension/sql_firewall--0.8.sql
%{_PGHOME}/lib
%{_PGHOME}/lib/sql_firewall.so

%changelog
* Sat Sep 05 2015 Satoshi Nagayasu <snaga@uptime.jp> - 0.8.0-1
- The first RPM release.
