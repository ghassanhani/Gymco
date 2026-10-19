import { test } from "node:test";
import assert from "node:assert/strict";
import { alertsFor } from "../../site/admin/lib/alerts.js";

const base = { cost_today: 0, ai_failure_rate_today: 0 };

test("a quiet day has no alerts", () => {
  assert.deepEqual(alertsFor({ stats: base }), []);
});

test("AI spend over 80% of the budget warns, at 100% it is critical", () => {
  const warn = alertsFor({ stats: { ...base, cost_today: 8.6 }, config: { ai: { daily_budget_eur: 10 } } });
  assert.equal(warn[0].tone, "warn");
  assert.equal(warn[0].title, "AI spend at 86% of daily budget");
  const bad = alertsFor({ stats: { ...base, cost_today: 10 }, config: { ai: { daily_budget_eur: 10 } } });
  assert.equal(bad[0].tone, "bad");
  assert.equal(bad[0].title, "Photo logging is paused until 00:00 UTC");
});

test("an AI failure rate over 2% is critical", () => {
  const a = alertsFor({ stats: { ...base, ai_failure_rate_today: 0.09 } });
  assert.equal(a[0].title, "AI failures at 9% today");
});

test("a feature switched off is a standing warning so it isn't forgotten", () => {
  const a = alertsFor({ stats: base, config: { features: { photo_log: true, eating_out: false } } });
  assert.equal(a[0].title, "eating_out is switched off");
});

test("tickets waiting over a day, with the nearest deletion deadline", () => {
  const now = new Date("2026-10-19T12:00:00Z");
  const tickets = [
    { status: "new", created_at: "2026-10-17T12:00:00Z", kind: "general" },
    { status: "waiting", created_at: "2026-10-16T12:00:00Z", kind: "deletion", deadline_at: "2026-11-15T12:00:00Z" },
    { status: "solved", created_at: "2026-10-01T12:00:00Z", kind: "general" },
  ];
  const a = alertsFor({ stats: base, tickets, now });
  assert.equal(a[0].title, "2 tickets waiting over 24 h");
  assert.equal(a[0].sub, "1 is a deletion request · 27 days left");
});

test("most urgent first", () => {
  const a = alertsFor({
    stats: { ...base, cost_today: 9, ai_failure_rate_today: 0.05 },
    config: { ai: { daily_budget_eur: 10 } },
  });
  assert.deepEqual(a.map((x) => x.tone), ["bad", "warn"]);
});
