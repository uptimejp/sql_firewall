# ポリシーと動作モード

ポリシーは、ルール表の一致を許可と拒否のどちらとして扱うかを決めます。モードは違反時の挙動を決めます。

| `sql_firewall.policy` | 一致した SQL | 一致しない SQL |
| --- | --- | --- |
| `allowlist`（既定） | 許可 | ポリシー違反 |
| `denylist` | ポリシー違反 | 許可 |

ポリシーはクラスタ単位で、切り替えには再起動が必要です。両方のポリシーのルールは別々に保存されます。

| `sql_firewall.firewall` | 動作 |
| --- | --- |
| `disabled` | 検査と新規ルールの学習を停止します。 |
| `learning` | 実行した SQL を現在のポリシーのルールとして記録します。 |
| `permissive` | ポリシー違反の SQL に警告し、実行を続けます。 |
| `enforcing` | ポリシー違反の SQL をエラーで拒否します。 |

18・19 は通常の SQL に本体の64ビットクエリIDを使います。定数の違いが同じIDにまとまる場合があるため、行や特定の値に対する制限には PostgreSQL の権限や行レベルセキュリティを使います。DDL などのユーティリティ文は SQL テキストをハッシュ化します。書式を変えると別ルールになる場合があります。ルールはトップレベルの SQL を基準に設計します。

## 拒否リストを試す

[クイックスタート](quickstart.md)の手順5まで実行した一時クラスタで、集計 SQL を拒否リストに登録します。`admin` と `app` はそこで定義した関数です。

### 1. 拒否リストで対象の SQL を学習する

```sh
"$bindir/pg_ctl" -D "$demo/data" -m fast -w restart \
    -o '-c sql_firewall.policy=denylist'
admin -c "ALTER ROLE app_user SET sql_firewall.firewall = 'learning'"
app -Atc 'SELECT count(*) FROM demo_orders'
```

`2` が返り、`app_user` の拒否リストに登録されます。学習中に実行するのは、あとで拒否したい文だけです。

### 2. 警告と拒否を確認する

```sh
admin -c "ALTER ROLE app_user SET sql_firewall.firewall = 'permissive'"
app -Atc 'SELECT count(*) FROM demo_orders'
```

警告が表示され、結果 `2` が返ります。次に `enforcing` に切り替えます。

```sh
admin -c "ALTER ROLE app_user SET sql_firewall.firewall = 'enforcing'"
app -Atc 'SELECT state FROM demo_orders WHERE id = 2'
app -Atc 'SELECT count(*) FROM demo_orders'
```

1件検索は `pending` を返し、集計は `ERROR:  Prohibited SQL statement` で終了します。

### 3. 許可リストに戻す

```sh
"$bindir/pg_ctl" -D "$demo/data" -m fast -w restart \
    -o '-c sql_firewall.policy=allowlist'
app -Atc 'SELECT state FROM demo_orders WHERE id = 2'
```

許可リストのルールが再び読み込まれ、結果は `pending` です。
