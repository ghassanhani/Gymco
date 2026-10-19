// The dashboard's arithmetic, kept apart from the page so it can be tested.

/** Estimated cost of one AI scan in US dollars. Exact spend: Anthropic console. */
export const COST_PER_SCAN = 0.0005;

const sum = (xs) => xs.reduce((a, x) => a + x.n, 0);

/** The last 7 days of a daily series against the 7 before them. */
export function weekCompare(series) {
  const thisWeek = sum(series.slice(-7));
  const lastWeek = sum(series.slice(-14, -7));
  return { thisWeek, lastWeek, change: lastWeek === 0 ? null : (thisWeek - lastWeek) / lastWeek };
}

export const aiCost = (scansMonth) => scansMonth * COST_PER_SCAN;

export const fmtInt = (n) => new Intl.NumberFormat("en-US").format(n);

/** Bytes in decimal units, one decimal below 10. */
export function fmtBytes(n) {
  const units = ["B", "KB", "MB", "GB"];
  let i = 0;
  while (n >= 1000 && i < units.length - 1) {
    n /= 1000;
    i++;
  }
  return `${i === 0 || n >= 10 ? Math.round(n) : n.toFixed(1)} ${units[i]}`;
}

/** One bar per day, anchored to the bottom, 2px apart; the busiest day is full height. */
export function barGeometry(series, width, height) {
  const max = Math.max(0, ...series.map((d) => d.n));
  const step = width / series.length;
  const gap = 2;
  return series.map((d, i) => {
    const h = max === 0 ? 0 : (d.n / max) * height;
    return { x: i * step, y: height - h, w: Math.max(1, step - gap), h, day: d.day, n: d.n };
  });
}

export const cleanCode = (s) => s.replace(/\D/g, "");
