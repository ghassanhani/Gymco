// A section whose screen arrives in a later phase of this build.
import { h } from "../lib/dom.js";
import { empty } from "../lib/ui.js";

export const soon = (title) => (el) => el.append(h("div", { class: "card" }, empty(`${title} is on its way`, "This section ships in the next phase of the Control Center build.")));
