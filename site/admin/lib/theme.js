// Dark is the Control Center's default (Volt); light is one tap away and
// remembered in this browser.

import { h, icon } from "./dom.js";

const KEY = "gymco-admin-theme";

function saved() {
  try {
    return localStorage.getItem(KEY);
  } catch {
    return null;
  }
}

export function currentTheme() {
  return document.documentElement.dataset.theme === "light" ? "light" : "dark";
}

export function setTheme(t) {
  document.documentElement.dataset.theme = t;
  try {
    localStorage.setItem(KEY, t);
  } catch {
    // Private mode: the choice lasts for this page only.
  }
}

export const initTheme = () => (document.documentElement.dataset.theme = saved() === "light" ? "light" : "dark");

export function themeToggle() {
  const b = h("button", { type: "button", class: "icon-btn", id: "theme-toggle" });
  const draw = () => {
    const light = currentTheme() === "light";
    b.replaceChildren(icon(light ? "moon" : "sun"));
    b.setAttribute("aria-label", light ? "Switch to dark mode" : "Switch to light mode");
    b.title = light ? "Dark mode" : "Light mode";
  };
  b.addEventListener("click", () => {
    setTheme(currentTheme() === "light" ? "dark" : "light");
    draw();
  });
  draw();
  return b;
}
