#!/usr/bin/env python3
"""Render the Japanese and English guides to the GitHub Pages directory."""

import html
from pathlib import Path
import re
import subprocess


DOCS = Path(__file__).resolve().parent
PAGES = (
    ("index", "概要", "Overview"),
    ("installation", "インストール", "Installation"),
    ("quickstart", "クイックスタート", "Quickstart"),
    ("policies", "ポリシーと動作モード", "Policies and modes"),
    ("roles", "ログインロール別のモード", "Login role modes"),
    ("rules", "ルールの CSV 移行", "Promoting rules with CSV"),
    ("reference", "リファレンス", "Reference"),
    ("packaging", "パッケージによる導入", "Package installation"),
)
GUIDE_LINK = re.compile(
    r'href="(' + "|".join(re.escape(slug) for slug, _, _ in PAGES) + r')\.md(#[^"]*)?"'
)


def render(slug, language):
    english = language == "en"
    prefix = "../" if english else ""
    source = DOCS / "md" / ("en" if english else "") / f"{slug}.md"
    alternate = f"../{slug}.html" if english else f"en/{slug}.html"
    alternate_language = "ja" if english else "en"
    alternate_label = "日本語" if english else "English"
    skip_label = "Skip to content" if english else "本文へ移動"
    nav_label = "Guides" if english else "ガイド"
    title = source.read_text(encoding="utf-8").splitlines()[0].removeprefix("# ")
    article = subprocess.run(
        ["pandoc", "--from=gfm", "--to=html5", "--wrap=none", "--no-highlight", str(source)],
        check=True,
        capture_output=True,
        encoding="utf-8",
    ).stdout
    article = GUIDE_LINK.sub(lambda match: f'href="{match[1]}.html{match[2] or ""}"', article)
    navigation = []
    for target, japanese_label, english_label in PAGES:
        current = ' aria-current="page"' if target == slug else ""
        label = english_label if english else japanese_label
        navigation.append(f'<li><a href="{target}.html"{current}>{label}</a></li>')
    navigation_html = "\n".join(navigation)

    return f"""<!doctype html>
<!-- Generated from {source.relative_to(DOCS.parent).as_posix()} by docs/build_html.py. -->
<html lang="{language}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(title)} | sql_firewall</title>
  <link rel="stylesheet" href="{prefix}style.css">
  <link rel="alternate" hreflang="{alternate_language}" href="{alternate}">
</head>
<body>
  <a class="skip" href="#content">{skip_label}</a>
  <header class="masthead">
    <div class="header-inner">
      <a class="brand" href="index.html">sql_firewall</a>
      <div class="header-links">
        <a href="{alternate}" hreflang="{alternate_language}" lang="{alternate_language}">{alternate_label}</a>
        <a href="https://github.com/soudai/sql_firewall/tree/main">GitHub</a>
      </div>
    </div>
  </header>
  <div class="layout">
    <nav aria-label="{nav_label}">
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
    for language, folder in (("ja", ""), ("en", "en")):
        output = DOCS / "html" / folder
        output.mkdir(parents=True, exist_ok=True)
        for slug, _, _ in PAGES:
            (output / f"{slug}.html").write_text(
                render(slug, language), encoding="utf-8", newline="\n"
            )


if __name__ == "__main__":
    main()
