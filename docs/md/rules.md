# ルールの CSV 移行

ステージングで許可リストを学習し、本番のアプリ接続を `enforcing` にしたままルールを追加する手順です。管理コマンドを実行するスーパーユーザーの接続だけを `disabled` にします。

## 1. 同じルールIDを使える環境を用意する

移行元と移行先で PostgreSQL のメジャーバージョンと `sql_firewall.policy` をそろえます。CSV のキーは表やロールの名前ではなく、ロール OID とクエリIDです。クエリIDは参照先のオブジェクト OID の影響を受ける場合があるので、同じ名前を作り直した環境でも、ルールが一致するとは限りません。移行先の物理コピーを使って学習すると OID をそろえられます。メジャーバージョンを変更する場合は移行先のバージョンでルールを学習し直します。

以下の `STAGING_ADMIN_DSN`、`PROD_ADMIN_DSN` は管理者の接続先です。`STAGING_APP_DSN`、`PROD_APP_DSN` は同じアプリ用ロールの接続先です。例では [クイックスタート](quickstart.md)の `demo_orders` を使います。

## 2. ステージングで学習して書き出す

```sh
PGOPTIONS='-c sql_firewall.firewall=disabled' \
    psql "$STAGING_ADMIN_DSN" -X -v ON_ERROR_STOP=1 \
    -c "ALTER ROLE app_user SET sql_firewall.firewall = 'learning'"

psql "$STAGING_APP_DSN" -X -v ON_ERROR_STOP=1 \
    -c 'SELECT state FROM demo_orders WHERE id = 1'

PGOPTIONS='-c sql_firewall.firewall=disabled' \
    psql "$STAGING_ADMIN_DSN" -X -At -v ON_ERROR_STOP=1 \
    -c "SELECT sql_firewall_export_rule('/path/to/firewall.csv')"
```

`t` が返れば書き出し完了です。ファイルは **ステージングの PostgreSQL サーバー側**に作成されます。

## 3. 本番で検査を続けながら取り込む

書き出した CSV を本番サーバーに移し、PostgreSQL のサーバープロセスが読み取れる場所に置きます。取り込み前からアプリ用ロールは `enforcing` で運用します。

```sh
PGOPTIONS='-c sql_firewall.firewall=disabled' \
    psql "$PROD_ADMIN_DSN" -X -At -v ON_ERROR_STOP=1 \
    -c "SELECT sql_firewall_import_rule('/path/to/firewall.csv')"
```

`t` の場合、ルールのスナップショットがディスクに書き込まれています。`f` の場合はメモリには反映されていますが、ディスクへの書き込みが失敗しています。サーバーログでファイルエラーを確認し、解消後に同じ CSV を再取り込みします。

CSV の形式が不正な場合や、追加すると `sql_firewall.max` を超える場合は、反映前にエラーが出ます。既存のルールや実行回数は再取り込みで上書きされません。

## 4. アプリの接続で結果を確認する

```sh
psql "$PROD_APP_DSN" -X -At -v ON_ERROR_STOP=1 \
    -c 'SELECT state FROM demo_orders WHERE id = 1'
psql "$PROD_APP_DSN" -X -At -v ON_ERROR_STOP=1 \
    -c 'SELECT count(*) FROM demo_orders'
```

1件検索は `paid` を返します。本番ですでに集計が許可されていない場合、集計は `ERROR:  Prohibited SQL statement` のままです。この手順の統合テストは [tests/promote-rules.sh](https://github.com/soudai/sql_firewall/blob/main/tests/promote-rules.sh) にあります。
