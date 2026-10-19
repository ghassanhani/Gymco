// Numbers, sizes, money, times and chart geometry for the Control Center.
// No DOM here, so all of it is unit-tested.

export const fmtInt = (n) => (n == null || Number.isNaN(n) ? "—" : new Intl.NumberFormat("en-US").format(n));

export function fmtBytes(n) {
  const units = ["B", "KB", "MB", "GB"];
  let i = 0;
  let v = n ?? 0;
  while (v >= 1000 && i < units.length - 1) {
    v /= 1000;
    i++;
  }
  return `${i === 0 || v >= 10 ? Math.round(v) : v.toFixed(1)} ${units[i]}`;
}

export function fmtEur(n) {
  const v = Number(n ?? 0);
  if (v > 0 && v < 0.005) return "< €0.01";
  return `€${v.toFixed(2)}`;
}

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
export const dayLabel = (iso) => {
  const d = new Date(iso.length === 10 ? iso + "T00:00:00Z" : iso);
  return `${d.getUTCDate()} ${MONTHS[d.getUTCMonth()]}`;
};

export function relTime(iso, now = new Date()) {
  if (!iso) return "Never";
  const t = new Date(iso);
  const s = (now - t) / 1000;
  if (s < 90) return "Just now";
  if (s < 3600) return `${Math.round(s / 60)} min ago`;
  const sameDay = t.toISOString().slice(0, 10) === now.toISOString().slice(0, 10);
  if (sameDay || s < 6 * 3600) return `${Math.round(s / 3600)} h ago`;
  const yesterday = new Date(now - 86400000).toISOString().slice(0, 10);
  if (t.toISOString().slice(0, 10) === yesterday) return "Yesterday";
  return dayLabel(iso);
}

/** "+12%" against the previous period; lower-is-better metrics flip the tone. */
export function delta(cur, prev, { lowerIsBetter = false } = {}) {
  if (!prev) return cur ? { text: "New", tone: "flat" } : { text: "0%", tone: "flat" };
  const p = Math.round(((cur - prev) / prev) * 100);
  if (p === 0) return { text: "0%", tone: "flat" };
  const up = p > 0;
  return { text: `${up ? "+" : "−"}${Math.abs(p)}%`, tone: up !== lowerIsBetter ? "good" : "bad" };
}

/** A polyline across [w], baseline at [h], the peak 10px below the top. */
export function linePath(values, w, h, max = Math.max(0, ...values)) {
  const step = values.length > 1 ? w / (values.length - 1) : 0;
  return values
    .map((v, i) => `${i ? "L" : "M"}${(i * step).toFixed(1)} ${(max ? h - (v / max) * (h - 10) : h).toFixed(1)}`)
    .join(" ");
}

/** Bars on the baseline, one per value, each 60% of its slot. */
export function barPath(values, w, h, max = Math.max(0, ...values)) {
  const slot = w / values.length;
  const bw = slot * 0.6;
  return values
    .map((v, i) => {
      const bh = max ? (v / max) * (h - 10) : 0;
      return `M${(i * slot + (slot - bw) / 2).toFixed(1)} ${h}h${bw.toFixed(1)}v-${bh.toFixed(1)}h-${bw.toFixed(1)}z`;
    })
    .join(" ");
}

export const sparkPath = (values) => linePath(values, 120, 30, Math.max(0, ...values) * 1.1);

/** Shares of a {key: count} map, largest first; "unknown" is named honestly and last. */
export function mixRows(counts, labels) {
  const total = Object.values(counts).reduce((a, b) => a + b, 0);
  if (!total) return [];
  return Object.entries(counts)
    .map(([k, n]) => ({ key: k, label: k === "unknown" ? "Not reported yet" : labels[k] ?? k, n, pct: Math.round((n / total) * 100) }))
    .sort((a, b) => (a.key === "unknown") - (b.key === "unknown") || b.n - a.n);
}
