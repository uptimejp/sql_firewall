# クイックスタート

一時クラスタで、注文を1件ずつ読む SQL を学習し、未登録の集計 SQL に警告・拒否を出します。Linux または WSL の同じシェルで順番に実行してください。対象バージョンに sql_firewall が[インストール済み](installation.md)であることが前提です。

## 1. 一時クラスタを起動する

一般の OS ユーザーで実行します。接続先は専用ディレクトリの Unix ソケットです。

```sh
PG_CONFIG="${PG_CONFIG:-pg_config}"
bindir="$("$PG_CONFIG" --bindir)"
demo="$(mktemp -d /tmp/sqlfw-demo.XXXXXX)"
"$bindir/initdb" -D "$demo/data" -A trust --no-locale
cat >> "$demo/data/postgresql.conf" <<EOF
listen_addresses = ''
unix_socket_directories = '$demo'
port = 55432
shared_preload_libraries = 'sql_firewall'
sql_firewall.firewall = 'disabled'
EOF
"$bindir/pg_ctl" -D "$demo/data" -l "$demo/server.log" -w start

admin() {
    "$bindir/psql" -X -v ON_ERROR_STOP=1 -h "$demo" -p 55432 \
        -U "$(id -un)" -d postgres "$@"
}
app() {
    "$bindir/psql" -X -v ON_ERROR_STOP=1 -h "$demo" -p 55432 \
        -U app_user -d postgres "$@"
}
```

## 2. アプリ用ロールを用意する

```sh
admin <<'SQL'
CREATE EXTENSION sql_firewall;
CREATE ROLE app_user LOGIN;
CREATE TABLE demo_orders (id integer PRIMARY KEY, state text NOT NULL);
INSERT INTO demo_orders VALUES (1, 'paid'), (2, 'pending');
GRANT SELECT ON demo_orders TO app_user;
ALTER ROLE app_user SET sql_firewall.firewall = 'learning';
SQL
```

## 3. 1件検索の形を学習する

```sh
app -Atc 'SELECT state FROM demo_orders WHERE id = 1'
app -Atc 'SELECT state FROM demo_orders WHERE id = 2'
```

結果は `paid`、`pending` です。この例では定数 `1` と `2` だけが異なるため、1件のルールとして学習されます。次の表示で、正規化された SQL と `calls = 2` を確認できます。

```sh
admin -c "
SELECT query, calls
FROM sql_firewall.sql_firewall_statements
WHERE userid = (SELECT oid FROM pg_roles WHERE rolname = 'app_user');"
```

## 4. 未登録の集計に警告を出す

```sh
admin -c "ALTER ROLE app_user SET sql_firewall.firewall = 'permissive'"
app -Atc 'SELECT count(*) FROM demo_orders'
```

```text
WARNING:  Prohibited SQL statement
2
```

## 5. 未登録の集計を拒否する

```sh
admin -c "ALTER ROLE app_user SET sql_firewall.firewall = 'enforcing'"
app -Atc 'SELECT state FROM demo_orders WHERE id = 2'
app -Atc 'SELECT count(*) FROM demo_orders'
```

1件検索は `pending` を返します。集計は `ERROR:  Prohibited SQL statement` で終了します。`permissive` で実行した文は新しいルールに追加されないためです。

```sh
admin -Atc 'SELECT sql_warning, sql_error FROM sql_firewall.sql_firewall_stat'
```

この手順だけを実行した場合、結果は `1|1` です。

## 6. 一時クラスタを停止する

同じクラスタで[拒否リスト](policies.md)を試す場合は、起動したまま次のガイドに進みます。終了するときは次を実行します。

```sh
"$bindir/pg_ctl" -D "$demo/data" -m fast -w stop
```

停止後、データが不要になったら、`$demo` が指す一時ディレクトリを削除できます。
