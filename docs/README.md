# ドキュメントの更新

`docs/md` の Markdown を編集し、Python 3.10 以降と Pandoc 3 で HTML を再生成します。リポジトリルートで次を実行して、Markdown と生成された HTML を合わせてコミットします。

```sh
python3 docs/build_html.py
python3 -m http.server --directory docs/html 8000
```

ローカルプレビューの入口は `http://localhost:8000/` です。ナビゲーションとページ名は `docs/build_html.py`、スタイルは `docs/html/style.css` にあります。

GitHub Pages の公開ソースは **GitHub Actions** です。`main` で `docs/html` を更新すると、公開ワークフローがそのディレクトリをサイトとして配信します。公開される HTML と CSS はリポジトリに含まれます。
