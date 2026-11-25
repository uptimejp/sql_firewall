# パッケージによる導入

フォークには PGDG パッケージ向けの RPM spec と、Gentoo オーバーレイ向けの ebuild が含まれています。

## RPM

PGDG の PostgreSQL 開発パッケージ、C コンパイラ、GNU Make、`rpmbuild` を用意します。例えば PostgreSQL 19 向けなら `postgresql19-devel` を使います。spec の `pgmajor` に `9.4`、`18`、`19` を指定できます。9.4 にはアーカイブの開発パッケージが必要です。

```sh
topdir="$(rpm --eval '%{_topdir}')"
mkdir -p "$topdir/SOURCES"
git archive --format=tar.gz --prefix=sql_firewall-0.8.1/ \
    -o "$topdir/SOURCES/sql_firewall-0.8.1.tar.gz" HEAD
rpmbuild -ba --define 'pgmajor 19' packaging/rpm/sql_firewall.spec
```

生成先は `$topdir/RPMS` です。生成したバイナリ RPM を `rpm -qpl` で調べると、拡張の共有ライブラリ、SQL スクリプト、control ファイルを確認できます。インストールする RPM を選んで実行します。

```sh
sudo dnf install /path/to/generated-postgresql19-sqlfirewall.rpm
```

独自の場所に PostgreSQL を入れた場合は `--define 'pg_config /path/to/bin/pg_config'` で選べます。ビルドは `pgmajor` と `pg_config` のメジャーバージョンが一致することを確認します。[RPM spec とビルド手順](https://github.com/soudai/sql_firewall/tree/main/packaging/rpm)

## Gentoo

[ebuild のディレクトリ](https://github.com/soudai/sql_firewall/tree/main/packaging/gentoo/dev-db/sql-firewall)をローカルオーバーレイの `dev-db/sql-firewall` にコピーします。この ebuild はフォークの `main` をビルドします。

例えば PostgreSQL 18 向けにビルドするなら、Portage の `package.use` に次の項目を指定します。

```text
dev-db/sql-firewall postgres_targets_postgres18
```

```sh
ebuild /path/to/overlay/dev-db/sql-firewall/sql-firewall-9999.ebuild manifest
emerge --ask dev-db/sql-firewall
```

利用できる PostgreSQL スロットは、使用中の Gentoo リポジトリと `postgres-multi` eclass によって決まります。[Gentoo オーバーレイの手順](https://github.com/soudai/sql_firewall/tree/main/packaging/gentoo)

パッケージをインストールした後は、[プリロードと拡張の作成](installation.md)を行います。
