// A small Markdown reader for the Website editor: headings, paragraphs,
// bullet and numbered lists, bold, italic and links. The parser is pure and
// tested; the renderer builds DOM nodes with h(), so no text is ever parsed
// as HTML and only http(s), mailto and site-relative links become links.

import { h } from "./dom.js";

const SAFE_HREF = /^(https?:\/\/|mailto:|\/[^/]|\/$|#)/i;

/** Inline text → [{t:"text",s}|{t:"b",kids}|{t:"i",kids}|{t:"a",href,kids}]. */
export function parseInline(s) {
  const out = [];
  let buf = "";
  let i = 0;
  const flush = () => {
    if (buf) out.push({ t: "text", s: buf });
    buf = "";
  };
  while (i < s.length) {
    if (s.startsWith("**", i)) {
      const j = s.indexOf("**", i + 2);
      if (j > i + 2) {
        flush();
        out.push({ t: "b", kids: parseInline(s.slice(i + 2, j)) });
        i = j + 2;
        continue;
      }
    }
    if ((s[i] === "*" || s[i] === "_") && !/\s/.test(s[i + 1] ?? " ") && (s[i] === "*" || !/[\p{L}\d]/u.test(s[i - 1] ?? ""))) {
      const j = s.indexOf(s[i], i + 1);
      if (j > i + 1 && !/\s/.test(s[j - 1])) {
        flush();
        out.push({ t: "i", kids: parseInline(s.slice(i + 1, j)) });
        i = j + 1;
        continue;
      }
    }
    if (s[i] === "[") {
      const m = /^\[([^\]]+)\]\(([^)\s]+)\)/.exec(s.slice(i));
      if (m) {
        flush();
        out.push({ t: "a", href: m[2], kids: parseInline(m[1]) });
        i += m[0].length;
        continue;
      }
    }
    buf += s[i++];
  }
  flush();
  return out;
}

/** Markdown → blocks: {type:"h",level,kids} | {type:"p",kids} | {type:"ul"|"ol",items:[kids]}. */
export function parseMarkdown(text) {
  const blocks = [];
  let para = [];
  let list = null;
  const endPara = () => {
    if (para.length) blocks.push({ type: "p", kids: parseInline(para.join(" ")) });
    para = [];
  };
  const endList = () => {
    if (list) blocks.push(list);
    list = null;
  };
  for (const raw of String(text ?? "").split(/\r?\n/)) {
    const line = raw.trim();
    if (!line) {
      endPara();
      endList();
      continue;
    }
    const head = /^(#{1,6})\s+(.*)$/.exec(line);
    if (head) {
      endPara();
      endList();
      blocks.push({ type: "h", level: head[1].length, kids: parseInline(head[2].trim()) });
      continue;
    }
    const item = /^([-*•]|\d+[.)])\s+(.*)$/.exec(line);
    if (item) {
      endPara();
      const type = /^\d/.test(item[1]) ? "ol" : "ul";
      if (!list || list.type !== type) {
        endList();
        list = { type, items: [] };
      }
      list.items.push(parseInline(item[2]));
      continue;
    }
    endList();
    para.push(line);
  }
  endPara();
  endList();
  return blocks;
}

export const safeHref = (href) => (SAFE_HREF.test(href) ? href : null);

const inlineNodes = (kids) => kids.map((k) => {
  switch (k.t) {
    case "b": return h("strong", {}, inlineNodes(k.kids));
    case "i": return h("em", {}, inlineNodes(k.kids));
    case "a": {
      const href = safeHref(k.href);
      return href ? h("a", { href, target: "_blank", rel: "noopener" }, inlineNodes(k.kids)) : h("span", {}, inlineNodes(k.kids));
    }
    default: return k.s;
  }
});

/** Markdown text → an array of DOM nodes. */
export function renderMarkdown(text) {
  return parseMarkdown(text).map((b) => {
    if (b.type === "h") return h(`h${Math.min(b.level + 1, 6)}`, { class: `md-h${b.level}` }, inlineNodes(b.kids));
    if (b.type === "p") return h("p", {}, inlineNodes(b.kids));
    return h(b.type, {}, b.items.map((it) => h("li", {}, inlineNodes(it))));
  });
}

/** The plain words of a Markdown text, for summaries. */
export const plainText = (text) => parseMarkdown(text).flatMap((b) => (b.items ? b.items.flat() : b.kids)).map(function w(k) { return k.t === "text" ? k.s : k.kids.map(w).join(""); }).join(" ").replace(/\s+/g, " ").trim();
