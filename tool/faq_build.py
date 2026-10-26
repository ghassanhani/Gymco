"""Builds the FAQ from tool/faq_{en,ar,es}.py: assets/faq/faq.json for the
app, and the questions on site/support/index.html (English).

Run: python3 tool/faq_build.py
"""

import html
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tool"))

from faq_ar import AR  # noqa: E402
from faq_en import EN  # noqa: E402
from faq_es import ES  # noqa: E402

shapes = [[len(s["items"]) for s in lang] for lang in (EN, AR, ES)]
assert shapes[0] == shapes[1] == shapes[2], f"Languages differ: {shapes}"

os.makedirs(os.path.join(ROOT, "assets", "faq"), exist_ok=True)
with open(os.path.join(ROOT, "assets", "faq", "faq.json"), "w", encoding="utf-8") as f:
    json.dump({"en": EN, "ar": AR, "es": ES}, f, ensure_ascii=False, indent=1)
    f.write("\n")


def answer(a: str) -> str:
    lines = a.split("\n")
    out, bullets = [], []
    for line in lines:
        if line.startswith("• "):
            bullets.append(f"<li>{html.escape(line[2:])}</li>")
            continue
        if bullets:
            out.append("<ul>" + "".join(bullets) + "</ul>")
            bullets = []
        out.append(f"<p>{html.escape(line)}</p>")
    if bullets:
        out.append("<ul>" + "".join(bullets) + "</ul>")
    return "".join(out)


parts = []
for section in EN:
    parts.append(f"<h2>{html.escape(section['title'])}</h2>")
    for item in section["items"]:
        parts.append(
            f"<details class=\"faq-q\"><summary>{html.escape(item['q'])}</summary>{answer(item['a'])}</details>"
        )
block = "<!-- faq:start -->\n" + "\n".join(parts) + "\n<!-- faq:end -->"

page = os.path.join(ROOT, "site", "support", "index.html")
src = open(page, encoding="utf-8").read()
src, n = re.subn(r"<!-- faq:start -->.*?<!-- faq:end -->", lambda _: block, src, flags=re.S)
assert n == 1, "site/support/index.html needs the faq:start / faq:end markers"
open(page, "w", encoding="utf-8").write(src)
print(f"FAQ: {sum(shapes[0])} questions in {len(EN)} sections")
