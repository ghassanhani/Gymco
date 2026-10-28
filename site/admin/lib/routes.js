// The twelve sections, their sidebar groups and the role each needs to open.

export const NAV = [
  { name: "Monitor", items: [{ id: "overview", label: "Overview", cap: "read", skel: "kpis" }, { id: "health", label: "System health", cap: "read", skel: "kpis" }] },
  { name: "People", items: [{ id: "accounts", label: "Accounts", cap: "support", skel: "form" }, { id: "support", label: "Support inbox", cap: "support", skel: "table" }] },
  {
    name: "App",
    items: [
      { id: "config", label: "Remote config", cap: "draft", skel: "form" },
      { id: "content", label: "Content", cap: "draft", skel: "form" },
      { id: "plans", label: "Plans & pricing", cap: "draft", skel: "form" },
      { id: "messaging", label: "Messaging", cap: "draft", skel: "table" },
      { id: "notifications", label: "Notifications", cap: "draft", skel: "form" },
    ],
  },
  { name: "Ship", items: [{ id: "releases", label: "Releases", cap: "read", skel: "table" }, { id: "website", label: "Website", cap: "draft", skel: "form" }] },
  { name: "Admin", items: [{ id: "team", label: "Team & audit log", cap: "team", skel: "table" }] },
];

export const PAGES = NAV.flatMap((g) => g.items.map((i) => ({ ...i, group: g.name })));

export function parseHash(hash) {
  const [path, query = ""] = String(hash || "").replace(/^#\/?/, "").split("?");
  const id = PAGES.some((p) => p.id === path) ? path : "overview";
  return { id, params: Object.fromEntries(new URLSearchParams(query)) };
}
