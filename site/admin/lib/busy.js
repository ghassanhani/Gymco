// Any button that starts a request shows a spinner and stays locked until the
// request (and any it chains into) settles. Watching fetch covers both our
// admin calls and supabase-js (sign-in, codes, two-step), so no page has to
// opt in, and a double click can't send twice.

const START_WINDOW_MS = 1000; // a request this soon after a press belongs to it
const CHAIN_GAP_MS = 150; //     a follow-up request this soon after one ends does too

let pressed = null;
let pressedAt = 0;
let active = null;
let pending = 0;
let releaseTimer = 0;

function remember(btn) {
  if (!btn || btn.disabled || btn.dataset.noBusy != null) return;
  pressed = btn;
  pressedAt = performance.now();
}

// Busy is its own state, not `disabled`: a handler may disable the button on
// purpose meanwhile (a lock-out), and releasing must not undo that.
function lock(btn) {
  btn.classList.add("is-busy");
  btn.setAttribute("aria-busy", "true");
}

function unlock(btn) {
  btn.classList.remove("is-busy");
  btn.removeAttribute("aria-busy");
}

const busy = (btn) => btn?.classList?.contains("is-busy");

function started() {
  clearTimeout(releaseTimer);
  if (!active && pressed && performance.now() - pressedAt < START_WINDOW_MS && pressed.isConnected) {
    active = pressed;
    pressed = null;
    lock(active);
  }
  if (active) pending++;
  return !!active;
}

function settled() {
  if (--pending > 0) return;
  pending = 0;
  releaseTimer = setTimeout(() => {
    if (active) unlock(active);
    active = null;
  }, CHAIN_GAP_MS);
}

export function installBusy(win = window) {
  win.document.addEventListener("submit", (e) => {
    if (busy(e.submitter)) {
      e.preventDefault();
      e.stopImmediatePropagation();
    } else remember(e.submitter);
  }, true);
  win.document.addEventListener("click", (e) => {
    const btn = e.target.closest?.("button");
    if (busy(btn)) {
      e.preventDefault();
      e.stopImmediatePropagation();
    } else if (btn && btn.type !== "submit") remember(btn);
  }, true);
  const original = win.fetch.bind(win);
  win.fetch = (...args) => {
    const tracked = started();
    const p = original(...args);
    if (tracked) p.finally(settled).catch(() => {});
    return p;
  };
}
