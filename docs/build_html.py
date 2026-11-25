#!/usr/bin/env python3
"""Render the Japanese guides to the static GitHub Pages directory."""

import html
from pathlib import Path
import re
import subprocess


DOCS = Path(__file__).resolve().parent
PAGES = (
    ("index", "概要"),
    ("installation", "インストール"),
    ("quickstart", "クイックスタート"),
    ("policies", "ポリシーと動作モード"),
    ("roles", "ログインロール別のモード"),
    ("rules", "ルールの CSV 移行"),
    ("reference", "リファレンス"),
    ("packaging", "パッケージによる導入"),
)
GUIDE_LINK = re.compile(
    r'href="(' + "|".join(re.escape(slug) for slug, _ in PAGES) + r')\.md(#[^"]*)?"'
)


def render(slug):
    source = DOCS / "md" / f"{slug}.md"
    title = source.read_text(encoding="utf-8").splitlines()[0].removeprefix("# ")
    article = subprocess.run(
        ["pandoc", "--from=gfm", "--to=html5", "--wrap=none", "--no-highlight", str(source)],
        check=True,
        capture_output=True,
        encoding="utf-8",
    ).stdout
    article = GUIDE_LINK.sub(lambda match: f'href="{match[1]}.html{match[2] or ""}"', article)
    navigation = []
    for target, label in PAGES:
        current = ' aria-current="page"' if target == slug else ""
        navigation.append(f'<li><a href="{target}.html"{current}>{label}</a></li>')
    navigation_html = "\n".join(navigation)

    return f"""<!doctype html>
<!-- Generated from docs/md/{slug}.md by docs/build_html.py. -->
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(title)} | sql_firewall</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <a class="skip" href="#content">本文へ移動</a>
  <header class="masthead">
    <div class="header-inner">
      <a class="brand" href="index.html">sql_firewall</a>
      <a href="https://github.com/soudai/sql_firewall/tree/main">GitHub</a>
    </div>
  </header>
  <div class="layout">
    <nav aria-label="ガイド">
      <ul>
{navigation_html}
      </ul>
    </nav>
    <main id="content">
{article.rstrip()}
    </main>
  </div>
</body>
</html>
"""


def main():
    output = DOCS / "html"
    output.mkdir(exist_ok=True)
    for slug, _ in PAGES:
        (output / f"{slug}.html").write_text(render(slug), encoding="utf-8", newline="\n")


if __name__ == "__main__":
    main()
