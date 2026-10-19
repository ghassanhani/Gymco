// The eleven sections, their sidebar groups and the role each needs to open.

export const NAV = [
  { name: "Monitor", items: [{ id: "overview", label: "Overview", cap: "read" }, { id: "health", label: "System health", cap: "read" }] },
  { name: "People", items: [{ id: "accounts", label: "Accounts", cap: "support" }, { id: "support", label: "Support inbox", cap: "support" }] },
  {
    name: "App",
    items: [
      { id: "config", label: "Remote config", cap: "draft" },
      { id: "content", label: "Content", cap: "draft" },
      { id: "plans", label: "Plans & pricing", cap: "draft" },
      { id: "messaging", label: "Messaging", cap: "draft" },
    ],
  },
  { name: "Ship", items: [{ id: "releases", label: "Releases", cap: "read" }, { id: "website", label: "Website", cap: "draft" }] },
  { name: "Admin", items: [{ id: "team", label: "Team & audit log", cap: "team" }] },
];

export const PAGES = NAV.flatMap((g) => g.items.map((i) => ({ ...i, group: g.name })));

export function parseHash(hash) {
  const [path, query = ""] = String(hash || "").replace(/^#\/?/, "").split("?");
  const id = PAGES.some((p) => p.id === path) ? path : "overview";
  return { id, params: Object.fromEntries(new URLSearchParams(query)) };
}
