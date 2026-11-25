# ログインロール別のモード

クラスタ既定のモードに加え、スーパーユーザーがログインロールごとの既定値を設定できます。例えば既存アプリから順に `enforcing` を導入し、別のアプリは `permissive` の警告を見ながらルールを整備できます。

## アプリを段階的に切り替える

[クイックスタート](quickstart.md)の `app_user` を例にします。管理者セッションで実行します。

```sql
ALTER ROLE app_user SET sql_firewall.firewall = 'permissive';
```

`app_user` で接続し直して確認します。

```sql
SHOW sql_firewall.firewall;
SELECT count(*) FROM demo_orders;
```

モードは `permissive` です。集計が未登録なら警告が出て、結果 `2` が返ります。実際の運用では、必要な文が学習済みであることを確認してから管理者が次を実行します。

```sql
ALTER ROLE app_user SET sql_firewall.firewall = 'enforcing';
```

接続プールの既存接続にも新しい設定を反映するには、プールから再接続します。`SET ROLE` で権限を切り替えたセッションは、接続時からのモードを引き継ぎます。ルールの照合には、SQL 実行時のユーザーIDが使われます。

## クラスタ既定に戻す

```sql
ALTER ROLE app_user RESET sql_firewall.firewall;
```

次の新規接続からクラスタ既定に従います。専用の管理作業には、スーパーユーザーの1接続だけを `disabled` にする方法もあります。その使い方は[ルールの CSV 移行](rules.md)を参照してください。

設定権限を委任していない一般ユーザーが `SET`、`ALTER ROLE`、接続オプションでファイアウォールモードを変更しようとすると、権限エラーになります。
