# sql_firewall guide

sql_firewall is a PostgreSQL extension that warns about or rejects SQL according to rules for each role. You can learn the statements an application normally runs and allow them, or register specific statement patterns to reject.

**Supported PostgreSQL versions** 9.4.x, 18.x, and 19.x

| What you want to do | Guide |
| --- | --- |
| Build and load the extension | [Installation](installation.md) |
| Try learning, warnings, and rejections on a temporary cluster | [Quickstart](quickstart.md) |
| Choose an allowlist or a denylist | [Policies and modes](policies.md) |
| Set different modes for application and maintenance logins | [Login role modes](roles.md) |
| Add rules learned in staging to production | [Promoting rules with CSV](rules.md) |
| Inspect rules and counters or look up a setting | [Reference and troubleshooting](reference.md) |
| Install from an RPM or a Gentoo ebuild | [Package installation](packaging.md) |

A rule is keyed by the role OID (`userid`) and query ID (`queryid`). Two `SELECT` statements that differ only in a constant can share a query ID. PostgreSQL privileges and row-level security continue to apply.

[Repository](https://github.com/soudai/sql_firewall/tree/main) · [Upstream issues](https://github.com/uptimejp/sql_firewall/issues)
