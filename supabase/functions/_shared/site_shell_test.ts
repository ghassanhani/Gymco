import { assert, assertEquals, assertStringIncludes } from "jsr:@std/assert@1.0.13";
import { PAGES, pagePath, renderPage, siteFiles } from "./site_shell.ts";

const body = {
  title: { en: "Support", ar: "الدعم", es: "Soporte" },
  markdown: { en: "# Help\n\nEmail **us**.\n\n<script>alert(1)</script>", ar: "# مساعدة", es: "# Ayuda" },
  updated: "2026-10-20",
};

Deno.test("site: pages map to their folders, home at the root", () => {
  assertEquals([...PAGES], ["home", "support", "privacy", "terms", "delete-account"]);
  assertEquals(pagePath("home", "en"), "site/index.html");
  assertEquals(pagePath("home", "ar"), "site/ar/index.html");
  assertEquals(pagePath("support", "en"), "site/support/index.html");
  assertEquals(pagePath("privacy", "es"), "site/privacy/es/index.html");
});

Deno.test("site: Markdown becomes HTML inside the shared shell, raw HTML is escaped", () => {
  const html = renderPage("support", "en", body);
  assertStringIncludes(html, '<html lang="en">');
  assert(!html.includes('dir="rtl"'));
  assertStringIncludes(html, "<title>Support · Gymco</title>");
  assertStringIncludes(html, "<h1>Help</h1>");
  assertStringIncludes(html, "<strong>us</strong>");
  assertStringIncludes(html, "&lt;script&gt;");
  assert(!html.includes("<script>"));
  assertStringIncludes(html, '<link rel="stylesheet" href="/style.css">');
  assertStringIncludes(html, "<header>");
  assertStringIncludes(html, "<main>");
  assertStringIncludes(html, "<footer>");
  assertStringIncludes(html, "2026-10-20");
});

Deno.test("site: Arabic pages are rtl and titles are escaped", () => {
  const html = renderPage("support", "ar", { ...body, title: { ...body.title, ar: "a < b" } });
  assertStringIncludes(html, '<html lang="ar" dir="rtl">');
  assertStringIncludes(html, "<title>a &lt; b · Gymco</title>");
  assertStringIncludes(html, "<h1>مساعدة</h1>");
});

Deno.test("site: a publish writes three files", () => {
  const files = siteFiles("home", body);
  assertEquals(files.map((f) => f.path), ["site/index.html", "site/ar/index.html", "site/es/index.html"]);
  assertStringIncludes(files[2].content, '<html lang="es">');
});
