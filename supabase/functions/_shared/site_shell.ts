// gymcoapp.com pages from Markdown: the same header, nav, <main> and footer
// as the hand-written pages, one file per language. Raw HTML in the
// Markdown is shown as text, never rendered, and links keep to safe schemes.

import { marked, Renderer } from "npm:marked@15.0.12";

export const PAGES = ["home", "support", "privacy", "terms", "delete-account"] as const;
export type Page = typeof PAGES[number];
export type Lang = "en" | "ar" | "es";
export const LANGS: readonly Lang[] = ["en", "ar", "es"];

export interface T3 {
  en: string;
  ar: string;
  es: string;
}
export interface PageBody {
  title: T3;
  markdown: T3;
  updated: string;
}

export function escapeHtml(s: string): string {
  return s.replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c]!));
}

const safeUrl = (href: string) => /^(https?:|mailto:|\/|#|\.)/i.test(href.trim()) ? href : "#";

const renderer = new Renderer();
renderer.html = ({ text }) => escapeHtml(text);
renderer.link = function ({ href, title, tokens }) {
  const t = title ? ` title="${escapeHtml(title)}"` : "";
  return `<a href="${escapeHtml(safeUrl(href))}"${t}>${this.parser.parseInline(tokens)}</a>`;
};
renderer.image = ({ href, title, text }) => {
  const t = title ? ` title="${escapeHtml(title)}"` : "";
  return `<img src="${escapeHtml(safeUrl(href))}" alt="${escapeHtml(text)}"${t}>`;
};

export function renderMarkdown(md: string): string {
  return marked.parse(md, { renderer, async: false, gfm: true }) as string;
}

/** Where a page's HTML lives in the repo: EN at the page's folder, AR and ES below it; home at the root. */
export function pagePath(page: Page, lang: Lang): string {
  const dir = page === "home" ? "" : `${page}/`;
  return `site/${dir}${lang === "en" ? "" : `${lang}/`}index.html`;
}

const UPDATED: Record<Lang, string> = { en: "Updated", ar: "آخر تحديث", es: "Actualizado" };
const NAV: Record<Lang, { support: string; privacy: string; terms: string; del: string }> = {
  en: { support: "Support", privacy: "Privacy", terms: "Terms", del: "Delete account" },
  ar: { support: "الدعم", privacy: "الخصوصية", terms: "الشروط", del: "حذف الحساب" },
  es: { support: "Soporte", privacy: "Privacidad", terms: "Términos", del: "Eliminar cuenta" },
};

const sub = (lang: Lang) => (lang === "en" ? "" : `${lang}/`);

export function renderPage(page: Page, lang: Lang, body: PageBody): string {
  const n = NAV[lang];
  const s = sub(lang);
  const title = escapeHtml(body.title[lang]);
  const dir = lang === "ar" ? ' dir="rtl"' : "";
  const updated = /^\d{4}-\d{2}-\d{2}$/.test(body.updated) ? `<p class="muted">${UPDATED[lang]}: ${body.updated}</p>\n` : "";
  return `<!doctype html>
<html lang="${lang}"${dir}>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title} · Gymco</title>
<link rel="icon" href="/favicon.png">
<link rel="apple-touch-icon" href="/icon.png">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Instrument+Serif:ital@1&family=Urbanist:wght@400;600;700&display=swap">
<link rel="stylesheet" href="/style.css">
</head>
<body>
<header><div class="wrap"><a class="brand" href="/${s}"><img src="/icon.png" alt="">Gymco</a>
<nav><a href="/support/${s}">${n.support}</a><a href="/privacy/${s}">${n.privacy}</a><a href="/terms/${s}">${n.terms}</a></nav></div></header>
<main><div class="wrap">
${renderMarkdown(body.markdown[lang])}${updated}</div></main>
<footer><div class="wrap"><span>© ${new Date().getUTCFullYear()} Gymco</span><a href="/privacy/${s}">${n.privacy}</a><a href="/terms/${s}">${n.terms}</a><a href="/support/${s}">${n.support}</a><a href="/delete-account/${s}">${n.del}</a></div></footer>
</body>
</html>
`;
}

/** The three files a publish writes. */
export function siteFiles(page: Page, body: PageBody): { path: string; content: string }[] {
  return LANGS.map((lang) => ({ path: pagePath(page, lang), content: renderPage(page, lang, body) }));
}
