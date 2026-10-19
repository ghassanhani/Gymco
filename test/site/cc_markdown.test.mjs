import { test } from "node:test";
import assert from "node:assert/strict";
import { parseInline, parseMarkdown, plainText, renderMarkdown, safeHref } from "../../site/admin/lib/markdown.js";

test("headings, paragraphs and lists become blocks", () => {
  const b = parseMarkdown("# Privacy policy\nYour diary lives on your phone.\nIt stays there.\n\n## What we keep\n- Your email\n- A backup\n\n1. one\n2. two");
  assert.deepEqual(b.map((x) => x.type), ["h", "p", "h", "ul", "ol"]);
  assert.equal(b[0].level, 1);
  assert.equal(b[1].kids[0].s, "Your diary lives on your phone. It stays there.");
  assert.equal(b[3].items.length, 2);
  assert.equal(b[4].items[1][0].s, "two");
});

test("bold, italic and links are read inline", () => {
  assert.deepEqual(parseInline("a **b** c"), [{ t: "text", s: "a " }, { t: "b", kids: [{ t: "text", s: "b" }] }, { t: "text", s: " c" }]);
  assert.equal(parseInline("*it*")[0].t, "i");
  assert.equal(parseInline("_it_")[0].t, "i");
  const a = parseInline("see [the terms](https://gymcoapp.com/terms/)")[1];
  assert.equal(a.t, "a");
  assert.equal(a.href, "https://gymcoapp.com/terms/");
  // Stray markers stay text.
  assert.deepEqual(parseInline("2 * 3 = 6"), [{ t: "text", s: "2 * 3 = 6" }]);
  assert.deepEqual(parseInline("snake_case_name"), [{ t: "text", s: "snake_case_name" }]);
});

test("only web, mail and site links are links", () => {
  assert.equal(safeHref("https://x.y"), "https://x.y");
  assert.equal(safeHref("mailto:support@gymcoapp.com"), "mailto:support@gymcoapp.com");
  assert.equal(safeHref("/privacy/"), "/privacy/");
  assert.equal(safeHref("javascript:alert(1)"), null);
  assert.equal(safeHref("data:text/html,x"), null);
});

test("raw HTML is text, never markup", () => {
  const b = parseMarkdown("<script>alert(1)</script> **bold**");
  assert.equal(b[0].kids[0].s, "<script>alert(1)</script> ");
  assert.equal(plainText("# Hi\n- **a** [b](/c)"), "Hi a b");
});

test("rendering builds nodes with text content only", () => {
  // A tiny document: enough for h() to build a tree we can inspect.
  class N { constructor(p) { Object.assign(this, { attrs: {}, kids: [], style: {} }, p); } append(...k) { this.kids.push(...k); } setAttribute(k, v) { this.attrs[k] = v; } addEventListener() {} }
  globalThis.Node = N;
  globalThis.document = { createElement: (tag) => new N({ tag }), createTextNode: (text) => new N({ text }) };
  const out = renderMarkdown("# T\n<b>x</b> and [go](javascript:1) or [ok](https://a.b)");
  assert.equal(out[0].tag, "h2");
  assert.equal(out[1].kids[0].text, "<b>x</b> and ");
  assert.equal(out[1].kids[1].tag, "span");
  assert.equal(out[1].kids[3].tag, "a");
  assert.equal(out[1].kids[3].attrs.href, "https://a.b");
  delete globalThis.document;
  delete globalThis.Node;
});
