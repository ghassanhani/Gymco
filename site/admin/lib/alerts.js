// The Overview's alert strip: what needs a person's attention today, most
// urgent first. Inputs are optional; a section that isn't loaded raises nothing.

const DAY = 86400000;

export function alertsFor({ stats = {}, config = null, tickets = null, now = new Date() }) {
  const out = [];
  const budget = config?.ai?.daily_budget_eur;
  if (budget > 0) {
    const share = (stats.cost_today ?? 0) / budget;
    if (share >= 1) {
      out.push({ tone: "bad", title: "Photo logging is paused until 00:00 UTC", sub: "Today's AI budget is spent. Write and search still work.", link: "#/config", action: "Adjust" });
    } else if (share >= 0.8) {
      out.push({ tone: "warn", title: `AI spend at ${Math.round(share * 100)}% of daily budget`, sub: `Photo logging pauses at €${budget.toFixed(2)}`, link: "#/config", action: "Adjust" });
    }
  }
  const fail = stats.ai_failure_rate_today ?? 0;
  if (fail > 0.02) {
    out.push({ tone: "bad", title: `AI failures at ${Math.round(fail * 100)}% today`, sub: "Over the 2% line. Check the model and prompt rollout.", link: "#/config", action: "Open" });
  }
  for (const [key, on] of Object.entries(config?.features ?? {})) {
    if (on === false) out.push({ tone: "warn", title: `${key} is switched off`, sub: "It stays off for everyone until it's turned back on.", link: "#/config", action: "Review" });
  }
  if (tickets) {
    const late = tickets.filter((t) => t.status !== "solved" && now - new Date(t.created_at) > DAY);
    if (late.length) {
      const deletions = late.filter((t) => t.kind === "deletion" && t.deadline_at);
      const soonest = Math.min(...deletions.map((t) => new Date(t.deadline_at) - now));
      out.push({
        tone: "bad",
        title: `${late.length} ticket${late.length === 1 ? "" : "s"} waiting over 24 h`,
        sub: deletions.length
          ? `${deletions.length} ${deletions.length === 1 ? "is a deletion request" : "are deletion requests"} · ${Math.ceil(soonest / DAY)} days left`
          : "Oldest first in the inbox",
        link: "#/support",
        action: "Open inbox",
      });
    }
  }
  const rank = { bad: 0, warn: 1, good: 2 };
  return out.sort((a, b) => rank[a.tone] - rank[b.tone]);
}
