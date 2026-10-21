# Gymco — design changes since the first draft

Everything that changed between the first Claude Design drafts and what is
live now, written to be applied back to the design files. Three files are
covered:

1. **App (Volt prototype)**: the phone app
2. **Landing page**: gymcoapp.com
3. **Control Center**: gymcoapp.com/admin

Values are exact unless marked "about".

## Repository

- Repo: https://github.com/ghassanhani/Gymco
- Commit history: https://github.com/ghassanhani/Gymco/commits/main
- Original design drafts:
  - Landing: [docs/superpowers/designs/landing/](https://github.com/ghassanhani/Gymco/tree/main/docs/superpowers/designs/landing/)
  - Control Center: [docs/superpowers/designs/control-center/](https://github.com/ghassanhani/Gymco/tree/main/docs/superpowers/designs/control-center/)


---

## 1. App (Volt prototype)

**Source files:**
- Colours, type and radius: [lib/theme/volt.dart](https://github.com/ghassanhani/Gymco/blob/main/lib/theme/volt.dart)
- Component kit (cards, chips, buttons, tab bar): [lib/ui/kit/kit.dart](https://github.com/ghassanhani/Gymco/blob/main/lib/ui/kit/kit.dart)
- Icons: [lib/ui/kit/icon_paths.dart](https://github.com/ghassanhani/Gymco/blob/main/lib/ui/kit/icon_paths.dart)
- Motion: [lib/ui/kit/motion.dart](https://github.com/ghassanhani/Gymco/blob/main/lib/ui/kit/motion.dart)
- Splash: [lib/ui/common/splash.dart](https://github.com/ghassanhani/Gymco/blob/main/lib/ui/common/splash.dart)
- Today: [lib/ui/today/today_screen.dart](https://github.com/ghassanhani/Gymco/blob/main/lib/ui/today/today_screen.dart), [lib/ui/today/catchup_screen.dart](https://github.com/ghassanhani/Gymco/blob/main/lib/ui/today/catchup_screen.dart), [lib/ui/today/announcement_card.dart](https://github.com/ghassanhani/Gymco/blob/main/lib/ui/today/announcement_card.dart)
- Food: [lib/ui/food/](https://github.com/ghassanhani/Gymco/tree/main/lib/ui/food/)
- Train: [lib/ui/train/](https://github.com/ghassanhani/Gymco/tree/main/lib/ui/train/)
- Progress and awards: [lib/ui/progress/](https://github.com/ghassanhani/Gymco/tree/main/lib/ui/progress/)
- Me, Pro and account: [lib/ui/me/](https://github.com/ghassanhani/Gymco/tree/main/lib/ui/me/)
- Onboarding: [lib/ui/onboarding/onboarding_screen.dart](https://github.com/ghassanhani/Gymco/blob/main/lib/ui/onboarding/onboarding_screen.dart)
- Sign-in emails: [supabase/templates/](https://github.com/ghassanhani/Gymco/tree/main/supabase/templates/)

### 1.1 Foundations

#### Type
- **All text is 8% larger** than in the prototype. Every size is multiplied
  by 1.08, on top of the phone's own text-size setting. Scale every text
  style in the file by 1.08, or note the multiplier on the type page.
- No letter spacing anywhere, with a 1.45 line height, as the prototype's
  device frame set them.
- Fonts are unchanged: Urbanist for text, Instrument Serif Italic for the
  single accent word in titles, and IBM Plex Sans Arabic for Arabic. In
  Arabic, the accent word is bold sans in lime, because Instrument Serif has
  no Arabic letters.
- Clocks read `0:06` and `24:18` (no leading zero on minutes).

#### Corner radius
| Element | Prototype | Now |
|---|---|---|
| Cards and list rows | 24 | **18** |
| Today's workout card | 24 | **20** |
| Pro plan cards | — | **20** |
| Sheets | 30 | 30 |

#### Light mode (new)
The prototype was dark only. There are now two palettes. **Dark is still the
default.** People choose in **Me → Appearance**: Dark, Light, or Same as phone.

| Token | Dark (original) | Light |
|---|---|---|
| bg (page) | `#0A0B09` | `#FFFFFF` |
| card | `#15171A` | `#FFFFFF` + 1 px border `line` |
| card2 (raised, tiles) | `#1F2226` | `#EEF0E8` |
| sheet | `#111315` | `#FFFFFF` |
| soft (lead cards, light only) | = card | `#F2F3EE`, **no border** |
| field (text inputs) | = card | `#EEF0E8` |
| line | `#2A2E33` | `#E2E5DC` |
| line2 | `#3A3F45` | `#CBD0C3` |
| t1 / t2 / t3 / t4 | `#F5F7F0` / `#C9CEC4` / `#8D948A` / `#5F665C` | `#10120E` / `#3B4038` / `#6A7066` / `#9AA095` |
| brand (lime fill) | `#C6F432` | `#C6F432` (same) |
| ink on lime | `#0A0B09` | `#0A0B09` (same) |
| brandInk (icon on lime wash) | `#D9FF5C` | `#4F7400` |
| brandWash | `#1A230D` | `#EAF6CC` |
| brandEdge | `#4D6B12` | `#A9D64A` |
| accent (lime type, serif word) | `#C6F432` | `#5F8A00` (deep olive) |
| lime lines (rings, outlines, charts) | `#C6F432` | `#7DB800` |
| ok / okWash | `#7CF0B0` / `#11301F` | `#16935A` / `#E1F3EA` |
| warn / warnWash / warnEdge | `#FFD23F` / `#2E2508` / `#6B5410` | `#B26B00` / `#FBF0D6` / `#E8C770` |
| protein (blue) | `#4CC9F0` | `#1C86C4` |
| carbs (orange) | `#FF9F43` | `#E07A1F` |
| fat (violet) | `#C084FC` | `#8B5CF6` |

**Light-mode rules:**
- The page is white. Every card-coloured surface gets a hairline border
  (`line`). Dark mode has no borders.
- Cards that lead a screen (Today's workout card) use `soft` `#F2F3EE` with
  no border.
- Text fields are filled `#EEF0E8` so they don't vanish on white.
- Unselected chips get an outline.
- The lime glow behind each screen is about **half** as strong as in dark.
- The tab bar and floating bars are frosted white. Status-bar icons are dark.
- The Gymco logo is drawn in ink, not lime.
- "A little white" tints over dark become "a little black" on light.
- The lime glow gradient stays the same in both modes:
  `#E4FF6A → #B6F02A → #5EE4A0` at stops 0 / 45% / 100%, running from top
  left to bottom right.

#### Motion (new)
- Pushed screens rise and fade in. iPhone keeps the native slide and
  swipe-back, with a fade.
- Tabs fade through when switched.
- Cards ease in one after another when a screen opens.
- The calorie ring sweeps. kcal, macros and water roll to new values.
- Badges pop. Picks turn from + to a tick. The tab indicator grows into place.
- Everything respects reduce-motion.

#### Splash (new)
The Gymco **G** in the Volt glow, 96 pt, centred on ink `#0A0B09`, in every
phone theme. The app's first frame shows the same G in the same place, holds
a beat, then grows slightly and fades into the app (800 ms, once per
launch). With reduce-motion it only fades.

#### App icon
The Gymco G in the Volt gradient.

#### Icons added
`ruler` (tape measure), `medal`, `mic`, `camera`, `scan` (barcode),
`list` (write), `food` (eat out). An exercise with no equipment shows a
dumbbell, not a dot. There are also badges for medicine ball, exercise ball
and foam roll.

---

### 1.2 Today
- **Top-right button:** a lime circle with a **medal** icon and the count of
  awards won. It opens Awards. It used to open settings.
- **Workout card:** smaller in both modes:
  - tighter padding
  - title **29 pt** (was 36)
  - a shorter button
  - a smaller dumbbell behind
  - radius 20
  
  In light mode it has no tint, no inner glow and no lime shadow, and sits
  on `soft` `#F2F3EE` with no border.
- **Workout card states:**
  - "No session planned", with *Set up your training* and Choose a routine
  - a workout left open, with a recover option
  - rest or skip today
  - train on a rest day
- **kcal ring when empty:** a **solid track**, not beads. When nothing is
  logged it reads "2,319 kcal to log", "Nothing logged yet…" and the
  protein, carbs and fat targets.
- **First-run card "Log your first meal"** (day one, nothing logged yet):
  - one compact row of **four equal tiles**: Search, Barcode, Photo, Voice
  - each tile is about 62 tall, radius 14, with a 28 px icon circle over an
    11 pt semibold label
  - card padding 14, gap 10, no tip line
  - Light: tiles `#F2F3EE`, **white circles**, **ink** icons
  - Dark: tiles `card2`, `brandWash` circles, lime icons
  - If Photo or Voice is switched off, Write and then Eat out take its place
- **Catch-up card:** shown after the first day when days were left unlogged.
  Lime wash with a clock icon and the line "6 days without food logs · Catch
  up in a few taps". It fills days from the usual day, or leaves them out.
- **Announcement card** (from the Control Center), in the app's language,
  with an optional link and a dismiss that sticks.
- **Hydration card** (was Water):
  - progress toward a daily goal of 35 ml/kg, +0.5 L on training days, or a
    goal you set
  - Glass, Bottle and Large buttons, plus undo
  - a sheet with each drink's time, a custom amount and the goal
  - Hydration and Trend weight cards now have icons
- **Steps** from Apple Health or Health Connect, when connected.

### 1.3 Food (Add food)
- **As a tab:** the same header as Today, Train, Progress and Me. A big
  title, the line under it, and a small chevron showing the meal can be
  changed. **No X.** Opened from a meal on Today, it keeps the compact title
  and the close button.
- **Six ways to add:** Search, Barcode, Write, Voice, Photo and **Eat out**
  (new).
  - Eat out: pick the dish, size and sides for an honest estimate (kcal,
    protein, ±20%). "Something else" asks the AI from a description, or
    takes a guess by hand.
- **Recipes** shelf (new): build from written ingredients, set servings, log
  a serving. Edit or delete from the shelf.
- **My meals** and **Custom** shelves.
- **Confirm sheet** before adding from Write, Voice, Photo and Barcode: what's
  about to be logged, the total and the meal, with **Confirm and add** or
  **Keep editing**.
- **Write:**
  - an "Ask AI" button for every unknown food at once
  - an **AI tag** on estimated foods
  - a bigger Add button and bigger totals in the add bar
  - the tab bar stays behind the keyboard
- **Photo:** a list of suggested foods, ticked once added, with **Add all**.
- Food rows are lighter. A large meal total no longer spills out of the meal
  header.

### 1.4 Train
- **No routines yet:** *Start an empty workout* and *Build my own routine*
  are **cards** like the template rows (icon, title, line, chevron), not big
  pill buttons. The lime icon marks the main one.
- **Exercise photos:** lists show each exercise's first photo as a thumbnail
  instead of the equipment badge. Tap it for full screen, swipe between start
  and end positions, and pinch to zoom.
- **Create your own exercise** when the library doesn't have it.
- A routine can run on several weekdays.
- **Live workout:**
  - **Rest timer** is a **lime card with a large countdown**
  - centred rest-timer label and a visible dashed border
  - lime glow on ticked sets
  - outlined −15s / Skip
  - "Then:" for the next exercise
  - a brighter rest-bar label and track
- **Swap exercise** mid-session, and **flag pain** on a set.

### 1.5 Progress
- **The four views are icon tiles**, not chips: Weight, Measure, Strength,
  Photos.
  - Each tile is an icon over its name: scale, ruler, dumbbell, camera.
  - The four are equal width, so all of them are in sight.
  - The selected tile is lime-edged on a lime wash.
- **Progress photos** (stored on the phone) with compare.
- A "strength held" insight.
- Streak pause (freezes).

### 1.6 Awards
- **13 enamel badges** replace the drawn medals:
  - first full day, protein week, first workout, 25 workouts
  - monthly challenge (its calendar plate shows the current month)
  - 7, 14, 30, 66 and 90-day streaks
  - comeback, 100 meals, 10 personal bests
- Locked badges are a greyscale pressing at 20% opacity.
- The challenge under way shows in colour.
- **The award page shows the badge in 3D:**
  - drag to turn it, tap to flip it
  - a chrome edge seen side-on, a moving highlight, and it springs to settle
  - the back is brushed steel, engraved with the award and the date earned
  - locked badges tilt but don't flip

### 1.7 Me
- **Sign-in card** at the top while signed out:
  - a 44 px brandWash circle with a user icon
  - the title "Sign in…" (17 pt bold), a muted line on what an account adds
  - a full-width **Sign in with email** button
  - hidden once signed in, where the Account row shows the email
- **Gymco Pro card:** lime, with a black pill in light mode. It currently
  says Pro is on for testers.
- **Appearance** row: Dark / Light / Same as phone.
- **Reminders:** meals, water and workouts. Each opens its own sheet to
  change the time.
- **Health data:** Apple Health or Health Connect.
- **Help** form (in-app support, which can also request account deletion).
- **Your data:** export as CSV or JSON, and delete everything.
- The **no-numbers mode is removed.** Calories, macros and weight always show.

### 1.8 Pro (Free vs Pro)
- **Plan cards you swipe** (Free, Pro, Lifetime), with monthly or yearly
  prices and what each plan includes.
- The cards are **as tall as their content**. The pager takes the tallest
  card's height, so there's no empty gap above the button.
- Card style: white (`card`), radius 20. The outline is `line2`, or
  `brandEdge` on the popular plan.
- Plan names and prices wrap at large text sizes.

### 1.9 Sign-in / Account
- The six-digit code field, plus the email's link, both sign in.
- The email field wants a name, an @ and a domain. Once something that isn't
  an email is typed, a line under the field says so; the button isn't just
  greyed out.
- **Sign-in emails** (new): the Gymco logo, a sign-in button and the code, in
  English, Arabic (right to left) or Spanish.

### 1.10 Onboarding / Welcome
- **Welcome:**
  - a capitalised **Get started** button with no arrow (no swipe)
  - three feature pages after it (logging, training, progress)
  - **full-bleed illustrations** that sit right on their titles and fade
    into the background
- **Five goals**, a projection card, manual macros, and recorded consent.
- **Age, height and weight fields:** the value is **26 pt extra-bold** with
  tabular digits. The unit sits beside it at 15 pt, muted. No extra padding
  pushes the number in from the field's edge.

### 1.11 New system screens
- **Maintenance** (a resting screen) and **Update required** (minimum build),
  both controlled by the Control Center.
- A dismissible **update nudge** for a recommended build.
- A **What's New** sheet, shown once per build.
- **"Photo logging rests until tomorrow"** when the AI is paused.

---

## 2. Landing page (gymcoapp.com)

**Source files:**
- Draft: [docs/superpowers/designs/landing/Landing.dc.html](https://github.com/ghassanhani/Gymco/blob/main/docs/superpowers/designs/landing/Landing.dc.html), [docs/superpowers/designs/landing/Landing-Phone.dc.html](https://github.com/ghassanhani/Gymco/blob/main/docs/superpowers/designs/landing/Landing-Phone.dc.html), [docs/superpowers/designs/landing/landing.css](https://github.com/ghassanhani/Gymco/blob/main/docs/superpowers/designs/landing/landing.css)
- Live: [site/index.html](https://github.com/ghassanhani/Gymco/blob/main/site/index.html), [site/landing.css](https://github.com/ghassanhani/Gymco/blob/main/site/landing.css), [site/landing.js](https://github.com/ghassanhani/Gymco/blob/main/site/landing.js)

The draft (`Landing.dc.html` / `Landing-Phone.dc.html`) was dark only.

- **Defaults:** dark theme and English.
- **Language switchers:** EN · ES · AR, with Arabic last.
- **Hero:** the **beta pill is removed**. The title wraps as two balanced
  lines; there's no fixed line break.
- **Navigation:** the menu marks the section on screen. The current link is
  t1, semibold, with a 2 px lime underline 6 px below.
- **Favicon:** rounded.
- **Buttons that send** (sign-up) show a spinner and ignore a second press.
- **Sign-up result:** a pill with a lime ✓ circle for success, and red text
  for errors.

### Light theme (new)
| Token | Draft | Now |
|---|---|---|
| --page | `#F5F6F1` | `#FFFFFF` |
| --band (grey sections) | `#ECEDE6` | `#F5F6F1` |
| --line | `#E0E3D9` | `#E2E5DC` |
| --card / --raised / --line-2 | `#FFFFFF` / `#EEF0E8` / `#CBD0C3` | unchanged |

- **Hero glow:** a big lime glow lights the hero from its top corner, with a
  soft mint glow on the opposite side. It sits on the page, so it runs up
  **behind the header**.
  - lime: radial 1100×820 at the top-left corner,
    `rgba(198,244,50,.42)` → `.14` at 45% → transparent at 72%
  - mint: radial 800×640 at the right edge, 60 px down,
    `rgba(94,228,160,.16)` → transparent at 70%
  - In Arabic (right to left) the two glows swap sides.
- **Header:** transparent over the glow. Once the page scrolls it fills with
  white at 80% opacity, an 18 px blur and a bottom border in `--line`.
- **Logo** in ink `#10120E`.
- **Cards on white** get a 1 px `--line` inset border:
  cards, modes, parse, rules, FAQ, boxes, image cards, the medal stage,
  stats, typed.
  - An open FAQ item takes `--line-2`.
  - The "hot" mode takes a 1.5 px lime border.
- **Cards on grey bands have no border.** The white card alone stands out.
- **Food rows:** lighter, `#F7F8F4`.
- **Plans:** Free and Lifetime sit plain (transparent, no border). **Pro** has
  a green frame, a `#B8EC1E → #6FBF1A` gradient at 135°, with a soft green
  shadow.
- **Footer:** no top border.

---

## 3. Control Center (gymcoapp.com/admin)

**Source files:**
- Drafts: [docs/superpowers/designs/control-center/](https://github.com/ghassanhani/Gymco/tree/main/docs/superpowers/designs/control-center/)
- Live: [site/admin/](https://github.com/ghassanhani/Gymco/tree/main/site/admin/). Styles are in [site/admin/theme.css](https://github.com/ghassanhani/Gymco/blob/main/site/admin/theme.css), components in [site/admin/lib/ui.js](https://github.com/ghassanhani/Gymco/blob/main/site/admin/lib/ui.js), busy buttons in [site/admin/lib/busy.js](https://github.com/ghassanhani/Gymco/blob/main/site/admin/lib/busy.js), pages in [site/admin/pages/](https://github.com/ghassanhani/Gymco/tree/main/site/admin/pages/)

- **Themes:** Volt dark, with a **light-mode toggle**.
- **Dropdowns** draw their own centred chevron, clear of the rounded edge.
  Apply this to every select.
- **Motion:**
  - eased hovers and presses
  - a sliding switch knob
  - sections settle in on arrival
  - sheets, dialogs and toasts ease in
  - all of it turned down for reduced motion
- **Skeleton loading:** each section shows a skeleton **shaped like what's
  coming** (tiles and a chart, a table, or a form) with a soft light sweeping
  across it. It stays until the section has rendered.
- **Busy buttons:** any button that calls the server shows a spinner and
  stays locked until the call, and any calls it chains into, finish.
- The Team page title reads **"Team & audit log"**.
- **Website page:** a Landing page editor, with the sign-up count and CSV
  export.
