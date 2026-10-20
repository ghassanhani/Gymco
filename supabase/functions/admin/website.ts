// gymcoapp.com pages as versioned Markdown, one draft per page. Publishing
// records the version and, when GitHub is set up, writes the rendered HTML
// into site/ so GitHub Pages deploys it.

import { checkT3 } from "../_shared/announcements.ts";
import { type Page, type PageBody, PAGES, siteFiles } from "../_shared/site_shell.ts";
import { type Ctx, fail, ok, type Reply, type Route } from "./handler.ts";
import type { Services } from "./services.ts";
import type { VersionRow } from "./store.ts";
import { versionedRoutes } from "./versioned.ts";

const today = () => new Date().toISOString().slice(0, 10);
const NAMES: Record<Page, string> = { support: "Support", privacy: "Privacy", terms: "Terms", "delete-account": "Delete account" };

export const basePage = (page?: string): PageBody => ({
  title: { en: NAMES[page as Page] ?? String(page), ar: "", es: "" },
  markdown: { en: "", ar: "", es: "" },
  updated: today(),
});

export function validatePage(input: unknown): { ok: boolean; body: PageBody; errors: { key: string; message: string }[] } {
  const b = (input && typeof input === "object" ? input : {}) as Record<string, unknown>;
  const title = checkT3(b.title, "title", 80);
  const markdown = checkT3(b.markdown, "markdown", 20_000);
  const errors = [...title.errors, ...markdown.errors];
  const updated = typeof b.updated === "string" && /^\d{4}-\d{2}-\d{2}$/.test(b.updated) && !Number.isNaN(Date.parse(b.updated)) ? b.updated : null;
  if (b.updated != null && !updated) errors.push({ key: "updated", message: "Date as YYYY-MM-DD" });
  return { ok: errors.length === 0, body: { title: title.value, markdown: markdown.value, updated: updated ?? today() }, errors };
}

const liveUrls = (page: Page) => ({
  en_url: `https://gymcoapp.com/${page}/`, ar_url: `https://gymcoapp.com/${page}/ar/`, es_url: `https://gymcoapp.com/${page}/es/`,
});
const editing = (r: VersionRow) => r.status === "draft" || r.status === "in_review";

export function websiteRoutes(s: Services): Record<string, Route> {
  const routes = versionedRoutes("website", {
    table: "website_pages",
    section: "website",
    kinds: PAGES,
    kindField: "page",
    validate: (body) => Promise.resolve(validatePage(body)),
    base: basePage,
  });

  /** Writes the published version's three files; says whether it got there. */
  async function commit(ctx: Ctx, page: Page, version: number): Promise<{ committed: boolean; error?: string }> {
    const gh = s.github();
    if (!gh) return { committed: false };
    const row = (await ctx.store.versions("website_pages", page)).find((r) => r.version === version);
    if (!row) return { committed: false, error: "no_version" };
    try {
      for (const f of siteFiles(page, validatePage(row.body).body)) await gh.putFile(f.path, f.content, `Website: ${page} v${version}`);
      return { committed: true };
    } catch (e) {
      return { committed: false, error: (e as Error).message };
    }
  }

  const withCommit = (base: Route): Route => ({
    cap: base.cap,
    run: async (ctx, body) => {
      const r = await base.run(ctx, body);
      if (r.status !== 200) return r;
      const { version } = r.body as { version: number };
      return ok({ ...(r.body as object), ...(await commit(ctx, body.page as Page, version)) });
    },
  });

  const get = routes["website.get"];
  return {
    ...routes,
    "website.get": {
      cap: get.cap,
      run: async (ctx, body): Promise<Reply> => {
        const r = await get.run(ctx, body);
        if (r.status !== 200) return r;
        const summary = await Promise.all(PAGES.map(async (page) => {
          const all = await ctx.store.versions("website_pages", page);
          const pub = all.find((x) => x.status === "published");
          const d = all.find(editing);
          return { page, published_version: pub?.version ?? null, draft_status: d?.status ?? null, updated: (pub?.body as PageBody | undefined)?.updated ?? null };
        }));
        return ok({ ...(r.body as object), live: liveUrls(body.page as Page), summary });
      },
    },
    "website.publish": withCommit(routes["website.publish"]),
    "website.rollback": withCommit(routes["website.rollback"]),
  };
}
