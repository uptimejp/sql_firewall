# ドキュメントの更新

日本語は `docs/md`、英語は `docs/md/en` の Markdown を編集します。Python 3.10 以降と Pandoc 3 で HTML を再生成します。リポジトリルートで次を実行して、Markdown と生成された HTML を合わせてコミットします。

```sh
python3 docs/build_html.py
python3 -m http.server --directory docs/html 8000
```

ローカルプレビューの入口は日本語が `http://localhost:8000/`、英語が `http://localhost:8000/en/` です。ナビゲーションとページ名は `docs/build_html.py`、共通のスタイルは `docs/html/style.css` にあります。

GitHub Pages の公開ソースは **GitHub Actions** です。`main` で `docs/html` を更新すると、公開ワークフローがそのディレクトリをサイトとして配信します。公開される HTML と CSS はリポジトリに含まれます。
