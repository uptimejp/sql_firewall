# sql_firewall ガイド

sql_firewall は、PostgreSQL が受け取る SQL に対して、ロールごとのルールに基づいて警告や拒否を行う拡張です。アプリが普段発行する文を学習して許可する使い方と、既知の文を登録して拒否する使い方があります。

**対応バージョン** PostgreSQL 9.4.x・18.x・19.x

| やりたいこと | ガイド |
| --- | --- |
| 拡張をビルドして PostgreSQL に導入する | [インストール](installation.md) |
| 一時クラスタで学習・警告・拒否を試す | [クイックスタート](quickstart.md) |
| 許可リストと拒否リストを使い分ける | [ポリシーと動作モード](policies.md) |
| アプリと運用担当でモードを分ける | [ログインロール別のモード](roles.md) |
| ステージングのルールを本番へ追加する | [ルールの CSV 移行](rules.md) |
| ルール、カウンター、設定値を確認する | [リファレンスとトラブルシューティング](reference.md) |
| RPM または Gentoo ebuild で導入する | [パッケージによる導入](packaging.md) |

ルールのキーはロール OID（`userid`）とクエリID（`queryid`）です。例えば、定数だけが異なる2つの `SELECT` は、同じクエリIDになる場合があります。PostgreSQL の `GRANT` や行レベルセキュリティも通常どおり適用されます。

[リポジトリ](https://github.com/soudai/sql_firewall/tree/main) · [上流の Issue 一覧](https://github.com/uptimejp/sql_firewall/issues)
