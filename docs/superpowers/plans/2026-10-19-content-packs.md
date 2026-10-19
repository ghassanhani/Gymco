# Content packs: the shared contract

Phase 3 of the Control Center. The dashboard edits a pack as a draft, the
`admin` function validates and publishes it, `app-config` serves it, and the
app downloads, verifies and merges it. Built-in content always stays; a pack
only adds to it or overrides it by id. A pack that fails its checksum is
ignored and the phone keeps the previous one.

## Transport

- `GET app-config` lists `packs: { <kind>: { version, checksum } }` (published only).
- `GET app-config?pack=<kind>` returns
  `{ kind, version, checksum, body_json }` where `body_json` is the
  **canonical JSON string** of the body and `checksum` is the lowercase hex
  SHA-256 of its UTF-8 bytes.
- Canonical JSON: object keys sorted (recursively), no whitespace, numbers and
  strings as `JSON.stringify` writes them. The server computes the checksum
  over this string at save time (`_shared/packs.ts` `canonicalJson`,
  `checksum`) and serves the same string, so the phone hashes exactly the
  bytes it received, then parses them.
- The app fetches a pack only when the listed version differs from the one it
  holds, and keeps it only when both the served checksum and the listed one
  match its own hash.

## Common rules

- `T3` = `{ en: string, ar: string, es: string }`, each non-empty after trim,
  at most 240 characters (names at most 80). Every text field is a `T3`; a
  missing language blocks publishing.
- Ids are `^[a-z0-9_]{1,40}$` unless stated, unique within the pack.
- At most 500 items per list.
- `errors` block publishing; `warnings` are shown but don't block. Both are
  `{ key, message }` with `key` a dotted path such as `items.3.name.es`.

## Kinds and bodies

### foods
`{ items: [{ id, name: T3, kcal, protein, carbs, fat, serving_g? }] }`
- Per 100 g. kcal 0–900; protein, carbs, fat each 0–100 and together ≤ 100;
  serving_g 1–2000.
- Warning when 4·protein + 4·carbs + 9·fat differs from kcal by more than
  25% (and more than 20 kcal): "Labneh: macros add up to 212 kcal, but kcal
  says 160 per 100 g. Check the numbers."
- App: each becomes a food with id `pack:<id>`, source `pack`, English name
  `name.en`; `localFoodName` returns `name.ar` / `name.es`.

### vocabulary
`{ units: [{ word, lang: "en"|"ar"|"es", unit: "piece"|"scoop"|"slice"|"tbsp"|"tsp"|"cup"|"handful"|"bowl" }] }`
- word 1–30 characters, unique per (word, lang).
- App: extra unit words for the Write parser; built-in words win on conflict.

### eating_out
`{ dishes: [{ id, group: "main"|"side", name: T3, g, kcal, p, c, f }] }`
- Per portion. g 1–2000, kcal 0–3000, p/c/f 0–300.
- App: added after the built-in dishes of the same group; an id equal to a
  built-in one replaces it.

### exercises
`{ items: [{ id, name: T3, primary: [muscle], secondary: [muscle], equipment?, level?, images?: [path], instructions?: [string] }], removed?: [id] }`
- Ids here follow free-exercise-db: `^[A-Za-z0-9_\-()]{1,80}$`.
- muscle ∈ chest, shoulders, triceps, biceps, forearms, lats, middle back,
  lower back, traps, abdominals, quadriceps, hamstrings, glutes, calves,
  adductors, abductors, neck. primary non-empty.
- level ∈ beginner, intermediate, expert.
- **Error** when `removed` contains an exercise used by a built-in template
  (`BUILT_IN_TEMPLATE_EXERCISES`) or by the published templates pack:
  "Removes “Barbell_Hip_Thrust”, used in 2 templates".
- App: items join the library (an id equal to a bundled one replaces it,
  shown by `name.en`); removed ids drop out of search and pickers, but past
  workouts still show them.

### templates
`{ items: [{ id, name: T3, level, routines: [{ name: T3, weekday: 0–6, items: [{ exercise, sets: 1–10, rep_low: 1–50, rep_high: rep_low–50, rest_s: 0–600, rir?: 0–5 }] }] }] }`
- 1–7 routines, 1–15 items each.
- **Error** when an item's exercise is in the published exercises pack's
  `removed` list.
- App: listed after the three built-in templates on Train; starting one
  creates its routines like a built-in template.

### awards
`{ items: [{ id, name: T3, description: T3, metric: "logged_days"|"workouts"|"streak_days", threshold: 1–1000 }] }`
- **Rule check (error):** awards reward showing up, never weight loss or
  eating less. Any name or description containing a blocked word (per
  language, `AWARD_BLOCKED_WORDS`) fails: "Awards can’t reward weight loss or
  eating less. Try showing up instead: “Logged 30 days” or “Trained 12 times
  this month”."
- App: shown with the built-in awards; earned when the metric reaches the
  threshold (logged_days = full days logged, workouts = workouts finished,
  streak_days = best streak).

### challenges
`{ items: [{ month: "YYYY-MM", title: T3, target: 4–31 }] }`
- One per month.
- App: the month's challenge uses `target` (default 12) and `title`.

### copy
`{ overrides: { <key>: T3 } }`
- key ∈ `COPY_KEYS`: emptyDayTitle, emptyDayBody, obWelcomeBody,
  welcomeBody, welcomeLogBody, welcomeTrainBody, welcomeProgressBody,
  obTargetsBody, remindMealBody, remindWorkoutBody. Unknown keys are errors.
- App: `copyText(context, key, builtIn)` returns the override for the app's
  language, falling back to the built-in string.

## Admin routes

`packs.get|save_draft|submit|discard|publish|rollback` through
`versionedRoutes("packs", { table: "content_packs", kinds: PACK_KINDS, ... })`,
each taking `kind`. `packs.get` also returns `warnings` for the draft and a
`summary` of every kind: `{ kind, published_version, draft_status, items }`.
`packs.check` validates a body without saving: `{ ok, errors, warnings }`.
`plans.grants` (cap `support`) lists manual entitlements:
`[{ user_id, email, plan, expires_at, granted_at }]`.
