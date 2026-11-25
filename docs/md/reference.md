# リファレンスとトラブルシューティング

## 設定パラメータ

| パラメータ | 既定値 | 適用範囲 |
| --- | --- | --- |
| `shared_preload_libraries` | PostgreSQL の設定に従う | `sql_firewall` を追加し、クラスタを再起動 |
| `sql_firewall.firewall` | `disabled` | クラスタ既定、ログインロール、スーパーユーザーのセッション。モードは `disabled` / `learning` / `permissive` / `enforcing` |
| `sql_firewall.policy` | `allowlist` | クラスタ単位。`denylist` に切り替えるには再起動 |
| `sql_firewall.max` | `5000` | クラスタのルール数の上限。最小値は `100`。変更後は再起動 |
| `compute_query_id`（18・19） | `auto` | 実行時のクエリIDに `auto` または `on` が必要 |

## ルールとカウンターを見る

拡張を作成したデータベースで、管理者セッションから実行します。クラスタ既定が `enforcing` の場合は、管理作業用の接続だけ `disabled` にする方法もあります。

```sql
SELECT userid, queryid, query, calls
FROM sql_firewall.sql_firewall_statements
ORDER BY calls DESC, userid, queryid
LIMIT 10;

SELECT sql_warning, sql_error
FROM sql_firewall.sql_firewall_stat;
```

`calls` は対応するルールに記録された実行回数です。`sql_warning` は `permissive` の警告数、`sql_error` は `enforcing` の拒否数です。カウンターはクラスタで共有されます。

## 管理関数

| 関数 | 動作 | 実行条件 |
| --- | --- | --- |
| `sql_firewall_export_rule(text)` | 現在のポリシーのルールをサーバー側の CSV へ書き出す | スーパーユーザー、`disabled` のセッション |
| `sql_firewall_import_rule(text)` | サーバー側の CSV からルールを追加 | スーパーユーザー、`disabled` のセッション |
| `sql_firewall_stat_reset()` | 警告・エラーのカウンターをリセット | スーパーユーザー |
| `sql_firewall_reset()` | 現在のポリシーのルールをすべて消去 | スーパーユーザー、`disabled` のセッション |

例えば、一時クラスタで警告・エラーのカウンターだけをリセットするには次を実行します。`sql_firewall_reset()` はルール自体を消去する別の操作です。

```sql
SELECT sql_firewall_stat_reset();
SELECT sql_warning, sql_error FROM sql_firewall.sql_firewall_stat;
```

直後の値は、同時に警告・拒否が発生していなければ `0 | 0` です。

一時クラスタで現在のポリシーの全ルールを消去するには、スーパーユーザーが `disabled` のセッションで次を実行します。

```sql
SELECT sql_firewall_reset();
SELECT count(*) FROM sql_firewall.sql_firewall_statements;
```

同時に学習・取り込みをしていなければ結果は `0` です。クラスタ全体のルールを消すため、既存のルールを使う環境では先に[CSV に書き出す](rules.md)と復元に使えます。

## よくあるエラー

| 症状 | 確認すること |
| --- | --- |
| `sql_firewall must be loaded via shared_preload_libraries` | プリロードに拡張を追加し、正しいクラスタを再起動したか |
| `could not access file "sql_firewall"` | 対象の `pg_config` でビルドとインストールを行ったか |
| `sql_firewall requires compute_query_id to be auto or on` | PostgreSQL 18・19 の設定が `auto` または `on` か |
| 想定していた SQL が `Prohibited SQL statement` になる | 接続ロール、現在のポリシーとモード、クエリID、DDL の書式が学習時と合っているか |
| ロールのモードが切り替わらない | `ALTER ROLE` を実行したあと、新規接続で試したか |
| CSV を移したあとルールが一致しない | 移行元と先のメジャーバージョン、ポリシー、ロールとオブジェクトの OID が一致しているか |
