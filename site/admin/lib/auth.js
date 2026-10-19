// Getting in: email code (or the email's link), then the authenticator app.
// Resolves with {email, role} once the session is at aal2 and the server
// confirms an admins row. Nothing here is trusted by the server; it checks
// both again on every request.

import { ADMIN_URL, ApiError, call, sb } from "./api.js";
import { clear, h } from "./dom.js";
import { themeToggle } from "./theme.js";

const IDLE_MS = 12 * 3600 * 1000;
const LOCK_MS = 15 * 60 * 1000;
const TRIES = 3;
const ACTIVE_KEY = "gymco-admin-active";
const LOCK_KEY = "gymco-admin-mfa-lock";

const store = {
  get: (k) => {
    try {
      return localStorage.getItem(k);
    } catch {
      return null;
    }
  },
  set: (k, v) => {
    try {
      localStorage.setItem(k, v);
    } catch {
      // Private mode: idle and lock tracking last for this page only.
    }
  },
};

export const markActive = () => store.set(ACTIVE_KEY, String(Date.now()));

export function idleTooLong(now = Date.now()) {
  const last = Number(store.get(ACTIVE_KEY));
  return last > 0 && now - last > IDLE_MS;
}

function lockedUntil() {
  const v = JSON.parse(store.get(LOCK_KEY) || "{}");
  return v.until && v.until > Date.now() ? v.until : 0;
}

function noteFailure() {
  const v = JSON.parse(store.get(LOCK_KEY) || "{}");
  const fails = (v.until && v.until > Date.now() ? 0 : v.fails ?? 0) + 1;
  store.set(LOCK_KEY, JSON.stringify(fails >= TRIES ? { fails: 0, until: Date.now() + LOCK_MS } : { fails }));
  return TRIES - fails;
}

const clearFailures = () => store.set(LOCK_KEY, "{}");

function frame(root, ...body) {
  clear(root).append(
    h("div", { class: "gate" },
      h("div", { class: "theme-corner" }, themeToggle()),
      h("div", { class: "card" },
        h("img", { class: "logo", src: "/icon.png", alt: "Gymco" }),
        h("div", { class: "small muted", style: { fontWeight: "600" } }, "Control Center"),
        ...body)));
}

const errorLine = () => h("div", { class: "small", role: "alert", style: { color: "var(--critical)", minHeight: "18px" } });

export async function gate(root, { expired = false } = {}) {
  if (idleTooLong()) {
    await sb.auth.signOut({ scope: "local" });
    expired = true;
  }
  for (;;) {
    const { data } = await sb.auth.getSession();
    if (!data.session) {
      await emailStep(root, expired);
      expired = false;
      continue;
    }
    const aal = await sb.auth.mfa.getAuthenticatorAssuranceLevel();
    if (aal.data?.currentLevel !== "aal2") {
      await (aal.data?.nextLevel === "aal2" ? challengeStep(root) : enrollStep(root));
      continue;
    }
    try {
      const me = await call("me");
      markActive();
      return me;
    } catch (e) {
      if (e instanceof ApiError && e.code === "not_admin") {
        await notAdmin(root, data.session.user.email);
        continue;
      }
      if (e instanceof ApiError && (e.status === 401 || e.code === "mfa_required")) continue;
      throw e;
    }
  }
}

function emailStep(root, expired) {
  return new Promise((resolve) => {
    const email = h("input", { class: "input", type: "email", autocomplete: "email", required: true, id: "admin-email" });
    const code = h("input", { class: "input code", inputmode: "numeric", autocomplete: "one-time-code", maxlength: "12", id: "email-code" });
    const err = errorLine();
    const send = h("button", { type: "submit", class: "btn primary" }, "Send sign-in code");
    let sentTo = "";

    const codeForm = h("form", { class: "stack", hidden: true, novalidate: true },
      h("div", { class: "muted small", id: "code-sent" }),
      h("label", { class: "field" }, h("span", {}, "Code from the email"), code),
      h("button", { type: "submit", class: "btn primary" }, "Continue"),
      h("button", { type: "button", class: "btn link", on: { click: () => { codeForm.hidden = true; emailForm.hidden = false; email.focus(); } } }, "Use another email"));

    const emailForm = h("form", { class: "stack", novalidate: true },
      expired ? h("div", { class: "banner warn", role: "status" }, h("div", {}, h("b", {}, "You were signed out"), h("div", { class: "small muted" }, "No activity for 12 hours. Unsaved drafts are kept in this browser."))) : null,
      h("label", { class: "field" }, h("span", {}, "Admin email"), email),
      send,
      h("span", { class: "small muted" }, "Only emails in the admins table can get past the next step."));

    emailForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      const v = email.value.trim();
      if (!v.includes("@")) return (err.textContent = "Enter your email.");
      send.disabled = true;
      const { error } = await sb.auth.signInWithOtp({ email: v, options: { shouldCreateUser: false, emailRedirectTo: ADMIN_URL } });
      send.disabled = false;
      if (error) return (err.textContent = /signup|not found|not allowed/i.test(error.message) ? "No Gymco account uses that email." : "Couldn't send the code. Try again in a minute.");
      sentTo = v;
      err.textContent = "";
      codeForm.querySelector("#code-sent").textContent = `We emailed ${v}. Open the link in it, or type the code.`;
      emailForm.hidden = true;
      codeForm.hidden = false;
      code.focus();
    });
    codeForm.addEventListener("submit", async (e) => {
      e.preventDefault();
      const token = code.value.replace(/\D/g, "");
      if (token.length < 6) return (err.textContent = "Enter the code from the email.");
      const { error } = await sb.auth.verifyOtp({ email: sentTo, token, type: "email" });
      if (error) return (err.textContent = "That code didn't work. Check it, or send a new one.");
      resolve();
    });
    // Arriving from the email's link: the session lands without a code.
    const { data: sub } = sb.auth.onAuthStateChange((event) => {
      if (event === "SIGNED_IN") {
        sub.subscription.unsubscribe();
        resolve();
      }
    });
    frame(root, h("h1", { style: { fontSize: "28px" } }, "Sign in"), emailForm, codeForm, err);
    email.focus();
  });
}

function codeInput() {
  return h("input", { class: "input code", inputmode: "numeric", autocomplete: "one-time-code", maxlength: "6", id: "totp", "aria-label": "Authenticator code" });
}

function challengeStep(root) {
  return new Promise((resolve) => {
    const input = codeInput();
    const err = errorLine();
    const go = h("button", { type: "submit", class: "btn primary" }, "Verify");
    const form = h("form", { class: "stack", novalidate: true },
      h("h1", { style: { fontSize: "24px" } }, "Enter your authenticator code"),
      h("p", { class: "muted", style: { margin: "0" } }, "The 6-digit code from the app you set up for Gymco."),
      input, go, err,
      h("button", { type: "button", class: "btn link", on: { click: async () => { await sb.auth.signOut({ scope: "local" }); resolve(); } } }, "Sign out"));
    const checkLock = () => {
      const until = lockedUntil();
      go.disabled = !!until;
      if (until) err.textContent = `Too many wrong codes. Try again at ${new Date(until).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" })}.`;
      return !!until;
    };
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      if (checkLock()) return;
      const code = input.value.replace(/\D/g, "");
      if (code.length !== 6) return (err.textContent = "Enter all 6 digits.");
      const factors = await sb.auth.mfa.listFactors();
      const factor = factors.data?.totp?.[0];
      if (!factor) return resolve();
      const { error } = await sb.auth.mfa.challengeAndVerify({ factorId: factor.id, code });
      if (error) {
        const left = noteFailure();
        input.value = "";
        if (!checkLock()) err.textContent = `That code didn't match. ${left} ${left === 1 ? "try" : "tries"} left before a 15-minute lock.`;
        return;
      }
      clearFailures();
      resolve();
    });
    frame(root, form);
    checkLock();
    input.focus();
  });
}

function enrollStep(root) {
  return new Promise(async (resolve) => {
    // A half-finished enrolment from an earlier visit would block a new one.
    const listed = await sb.auth.mfa.listFactors();
    for (const f of listed.data?.all ?? []) if (f.status !== "verified") await sb.auth.mfa.unenroll({ factorId: f.id });
    const { data, error } = await sb.auth.mfa.enroll({ factorType: "totp", friendlyName: "Gymco Control Center" });
    if (error) {
      frame(root, h("h1", { style: { fontSize: "24px" } }, "Couldn't start two-step setup"), h("p", { class: "muted" }, error.message),
        h("button", { type: "button", class: "btn primary", on: { click: () => resolve() } }, "Try again"));
      return;
    }
    const input = codeInput();
    const err = errorLine();
    const form = h("form", { class: "stack", novalidate: true },
      h("h1", { style: { fontSize: "24px" } }, "Set up two-step sign-in"),
      h("p", { class: "muted", style: { margin: "0" } }, "Every admin uses an authenticator app (Google Authenticator, 1Password, Authy). Scan this, then type the code it shows."),
      h("div", { class: "qr" }, h("img", { src: data.totp.qr_code, alt: "QR code for your authenticator app" })),
      h("details", {}, h("summary", { class: "small muted" }, "Can't scan? Type this key instead"), h("div", { class: "mono", style: { wordBreak: "break-all" } }, data.totp.secret)),
      input,
      h("button", { type: "submit", class: "btn primary" }, "Turn on"),
      err);
    form.addEventListener("submit", async (e) => {
      e.preventDefault();
      const code = input.value.replace(/\D/g, "");
      if (code.length !== 6) return (err.textContent = "Enter all 6 digits.");
      const r = await sb.auth.mfa.challengeAndVerify({ factorId: data.id, code });
      if (r.error) return (err.textContent = "That code didn't match. Check the time on your phone is set automatically.");
      resolve();
    });
    frame(root, form);
    input.focus();
  });
}

function notAdmin(root, email) {
  return new Promise((resolve) => {
    frame(root,
      h("h1", { style: { fontSize: "24px" } }, "This account isn't an admin"),
      h("p", { class: "muted", style: { margin: "0" } }, `You're signed in as ${email}. Ask the Owner to add you under Team.`),
      h("button", { type: "button", class: "btn", on: { click: async () => { await sb.auth.signOut({ scope: "local" }); resolve(); } } }, "Sign out"));
  });
}
