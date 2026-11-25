# インストール

拡張を動かす PostgreSQL と同じメジャーバージョンの `pg_config` とサーバーヘッダーを使います。対応バージョンは **9.4.x・18.x・19.x** です。RPM と Gentoo の手順は[パッケージによる導入](packaging.md)を参照してください。

## 1. ビルドとインストール

Linux または WSL で Git、C コンパイラ、GNU Make を使います。PostgreSQL をパッケージで導入している場合は、対象バージョンの開発パッケージも用意してください。

```sh
git clone --branch main https://github.com/soudai/sql_firewall.git
cd sql_firewall

export PG_CONFIG="$(command -v pg_config)"
"$PG_CONFIG" --version
"$PG_CONFIG" --pgxs
make USE_PGXS=1 PG_CONFIG="$PG_CONFIG"
sudo make USE_PGXS=1 PG_CONFIG="$PG_CONFIG" install
```

複数バージョンがある場合は `PG_CONFIG` に対象の絶対パスを指定します。インストール先に現在のユーザーが書き込める構成では `sudo` を省略できます。[PostgreSQL の PGXS ドキュメント](https://www.postgresql.org/docs/19/extend-pgxs.html)

## 2. サーバーでプリロードする

対象クラスタの `postgresql.conf` を編集します。`shared_preload_libraries` に既存のライブラリがある場合は、同じリストに `sql_firewall` を追加します。最初は `disabled` で起動すると、アプリ用ロールの学習を始める前に接続設定を準備できます。

```conf
shared_preload_libraries = 'sql_firewall'
sql_firewall.firewall = 'disabled'
```

18・19 では `compute_query_id` に既定の `auto` または `on` を使います。`pg_stat_statements` と併用する場合、18・19 では両方のロード順で動作確認済みです。9.4 での併用は `pg_stat_statements,sql_firewall` の順に指定します。

設定を反映するにはクラスタを再起動します。サービス管理下のクラスタは、そのサービスの再起動手順を使ってください。手動で起動したクラスタでは `pg_ctl` を使用できます。

```sh
"$("$PG_CONFIG" --bindir)/pg_ctl" -D "$PGDATA" -w restart
```

## 3. 拡張を作成して確認する

関数とビューを使うデータベースにスーパーユーザーで接続します。

```sql
CREATE EXTENSION sql_firewall;
SHOW shared_preload_libraries;
SHOW sql_firewall.firewall;
SELECT sql_warning, sql_error FROM sql_firewall.sql_firewall_stat;
```

プリロードに `sql_firewall` が含まれ、モードが `disabled` と表示されれば準備完了です。ルールと検査はクラスタ全体に適用され、管理関数とビューは拡張を作ったデータベースで使えます。

[クイックスタート](quickstart.md)では専用の一時クラスタで、学習と警告・拒否を試します。
