# Gymco — brand and features

Diet and training for lifters. iPhone and Android, in English, Arabic (full
right-to-left) and Spanish. This document describes the app as it is built
today (October 2026, TestFlight build 102).

---

## 1. Brand

### Who it is for
Lifters who want to eat to a goal and train with a plan in one app. They care
about strength and muscle, not just a number on the scale.

### Promise
> Log food in seconds, train with a plan, and keep a streak worth protecting.

### Principles the product holds to
- **Private by default.** The diary lives on the phone. No account is needed,
  there are no ads, and nothing is sold. Progress photos never leave the phone.
- **Measured, not guessed.** Calorie needs come from what you actually ate and
  how your trend weight moved, not from a formula alone.
- **Rewards showing up, not eating less.** No award is for losing weight or
  eating less. Logging, training and planned rest are what count.
- **Honest guesses beat blank days.** Eating out, a rough estimate or a
  catch-up fill is always better than leaving a day empty.
- **Safe floors.** Targets are never set below a safe calorie floor, and a
  cut never asks you to pay food back with cardio.

### Voice
Plain, direct and calm. It sounds like a knowledgeable coach, not a cheerleader.
- Short sentences. It says what happened and what to do next.
- Gives the reason when it matters: *"Three minutes or more for heavy
  compounds — shorter rest costs you reps, and reps are the stimulus."*
- Never shames: a missed workout "moved to the next day you train — the week
  slides, the order holds."
- One word in each title is set in the serif italic accent:
  *Your **progress***, *Log food **your way***, *Eating **out***.

### Name and logo
- Name: **Gymco** (domain gymcoapp.com).
- Mark: a lime "G" on a near-black rounded square (app icon). Source files are
  under `assets/brand/` and the iOS/Android icon sets.

### Visual identity — "Volt"
Dark-only: electric lime on near-black, pill buttons with a lime-to-mint glow,
and a serif italic accent in titles.

| Role | Colour | Hex |
|---|---|---|
| Background | near-black | `#0A0B09` |
| Card | | `#15171A` |
| Raised card | | `#1F2226` |
| Sheet | | `#111315` |
| Lines | | `#2A2E33` / `#3A3F45` |
| Text, primary → faint | | `#F5F7F0`, `#C9CEC4`, `#8D948A`, `#5F665C` |
| **Brand lime** | | **`#C6F432`** |
| Lime ink (text accents) | | `#D9FF5C` |
| Lime wash / edge | | `#1A230D` / `#4D6B12` |
| Text on lime | | `#0A0B09` |
| Good | mint | `#7CF0B0` |
| Warning | yellow | `#FFD23F` |
| **Protein** | blue | `#4CC9F0` |
| **Carbs** | orange | `#FF9F43` |
| **Fat** | violet | `#C084FC` |

- **Glow gradient** (primary buttons, highlights): `#E4FF6A → #B6F02A → #5EE4A0`.
- **Plan card glows:** Pro `#E4FF6A → #5EE4A0`, Lifetime `#4CC9F0 → #8B7CF6`.
- **Radii:** cards 24, rows 18, sheets 30; buttons are pills.

### Typography
| Use | Typeface |
|---|---|
| UI and body | **Urbanist** (Regular, Medium, SemiBold, Bold, ExtraBold) |
| Title accent (one word, italic) | **Instrument Serif Italic** |
| Arabic | **IBM Plex Sans Arabic** (Regular, SemiBold, Bold). Instrument Serif has no Arabic, so the accent word becomes bold sans in lime. |

Numbers use Western digits in every language, Arabic included.

### Imagery and icons
- Onboarding photography: real people mid-lift (kettlebell swing, dumbbell
  press), logging a meal, celebrating among medals.
- A custom stroke icon set (the "Volt" icons).
- Exercise photos: two frames per movement from the open
  [free-exercise-db](https://github.com/yuhonas/free-exercise-db).
- Award badges are 3D medals you can drag to turn over.

### Website and admin
- **gymcoapp.com:** home, support, privacy policy, terms, account deletion
  (same dark lime look). Support: `support@gymcoapp.com`.
- **gymcoapp.com/admin:** private dashboard, built on Untitled UI Foundations
  tokens with the brand ramp swapped for Gymco lime, in light and dark.

---

## 2. App structure

Four tabs: **Today · Food · Train · Me**, plus **Progress** (reached from
Today and Me). The tab bar hides while the keyboard is open.

---

## 3. Getting started

### Welcome
Three slides with photography: *Log food your way*, *Train with a plan*,
*See it add up*.

### Onboarding (4–5 steps)
1. **Goal**:
   - **Cut**: lose fat, keep muscle and strength.
   - **Maintain**: hold weight and keep logging honestly.
   - **Lean bulk**: gain 0.25–0.5% of body weight a week.
   - **Recomposition**: eat near maintenance and watch the waist, not the scale.
   - **Contest prep**: a cut worked back from a stage date.
2. **Body:** sex, age, height, weight.
3. **Activity level.**
4. **Rate**, for goals that change weight. Capped at 1% of body weight a week.
5. **Targets:** calories and protein / carbs / fat. Calculated, or set by hand
   ("Set my macros manually").

A health-data consent is asked before anything is stored.

---

## 4. Today

- **Calorie ring:** eaten against target, with protein, carbs and fat bars.
- **Meals:** breakfast, lunch, dinner and snacks, each with its own total.
- **Day strip:** scroll back through past days.
- **Training hero card:** today's planned routine, with these actions:
  - **Start** the session.
  - **Rest instead:** take a planned rest day.
  - **Skip:** the routine moves to the next training day.
  - **Train anyway** on a rest day.
  - **Not today.**
- **Water:**
  - Glass, bottle or large in one tap.
  - The goal is about 35 ml per kg of body weight, with +0.5 L on training days,
    kept between 1.5 and 5 L. You can also set it yourself.
- **Steps**, from Apple Health or Health Connect.
- **Catch-up card:** shown when recent days have nothing logged (see §5.7).

---

## 5. Food

### 5.1 Ways to log
| Mode | What it does |
|---|---|
| **Search** | The food database: built-in staples with names in English, Arabic and Spanish, plus Open Food Facts. |
| **Barcode** | Scans a pack and uses its own label numbers. If a product is missing, it offers to add it to Open Food Facts. |
| **Write** | Type the meal as you'd say it: "200g chicken breast, 150g rice and 10g olive oil", "2 eggs with two slices of bread", "a scoop of whey". It is read offline in all three languages. Anything it can't match can be estimated by AI. |
| **Dictate** | Say the meal; the speech becomes Write. |
| **Photo** | Photograph the plate and add an optional note, like "4 mini pizzas with beef and cheddar". AI suggests the foods and amounts, and you confirm or change them. Needs an account; 10 photo scans a day, free. |
| **Eating out** | Pick a restaurant type and dish for an honest rough estimate. "Something else" sends a written description to AI. |

- Rows estimated by AI carry an **AI tag**.
- A weight you type always overrides the AI's guess.
- Every log goes through a **confirm** step before it is saved.

### 5.2 Servings
Each food can be logged in grams or in servings (1 serving of N g, etc.).

### 5.3 Meals
You can view a meal, edit amounts, remove items, and copy it to today or tomorrow.

### 5.4 Recipes
Write the ingredients ("500g chicken breast, 300g rice, 2 tbsp olive oil") and
the number of servings; Gymco works out calories per serving. Ingredients not
in the database are listed and left out, so you can add them as custom foods.

### 5.5 Calorie floor
Targets are never set below a safe floor. To go lower you type the number
yourself, after a warning.

### 5.6 Cheat meals (Me → Safeguards)
- **Off, once a week, or twice a week.**
- **Banked:** planned ahead. A slice comes off each day before the meal, never
  below the floor and never from protein, so the week still averages on
  target. A slice over 300 kcal a day is flagged as steep.
- **Free:** not logged. That day is left out of the expenditure average but
  still counts toward the streak.
- Nothing is ever paid back with cardio.

### 5.7 Catch up
Fill days that have no food logged in one of three ways:
- **Your usual day**: from your average intake.
- **A rough number:** a calorie figure you set; protein is scaled to match.
- **Leave it out**, so it doesn't skew the expenditure average.

---

## 6. Train

### 6.1 Routines
- **Builder:** name, exercises, sets, reps, weight and rest between sets, and
  **one or more weekdays**. Assigning a day takes it away from any other
  routine.
- **Templates:**
  - Upper / Lower, 4 days (intermediate, 12–18 sets per muscle a week).
  - Push / Pull / Legs, 6 days (advanced).
  - Full body, 3 days (any level; the one to pick while cutting).
- **Weekly volume** per muscle, with the 10–20 hard sets a week guideline.
- A routine added mid-week never counts the earlier days as missed.

### 6.2 The sliding week
A missed training day isn't lost: its routine moves to the next free day, so
the block keeps its order even when the dates shift. The app explains this as
"Miss Wednesday and Wednesday's session waits for you Thursday."

### 6.3 Exercise library
- **870+ exercises**, with photos, main and helper muscles, equipment and
  level.
- Search, and browse by muscle or equipment.
- **Create a custom exercise** when one isn't found (main muscle + equipment).

### 6.4 Live workout
- Every set shows **last time's numbers**.
- **Set types:** warm-up, normal, to failure, drop set. Warm-ups are logged but
  don't count toward volume.
- **Rest timer**, with suggested rest per exercise. Heavy compounds suggest
  3 minutes or more.
- **Swap an exercise** when the machine is taken or it hurts. Alternatives are
  ranked by the same main muscle, then the same movement pattern.
- **Flag pain** (shoulder, elbow, wrist, back, hip, knee, other):
  - **An ache:** carry on, or lighten the weight by 10%.
  - **Sharp pain:** stop the exercise, or swap it.
  - Next time, the exercise shows a reminder of the last flagged pain.
- **Interrupted workouts:** a session left open for 3 hours or more can be
  resumed or finished later.
- **Workout done** summary:
  - volume, sets and personal bests
  - estimated one-rep max (Epley)
  - unticked sets are left out of the log, and the summary says so
  - the session can be shared

---

## 7. Progress

| Tab | What it shows |
|---|---|
| **Weight** | A trend weight that ignores daily noise, a projection, and weigh-ins from your scale via Apple Health or Health Connect. |
| **Measure** | Waist, at the navel and relaxed. It moves slower than the scale but is more honest about fat loss. |
| **Strength** | Estimated strength per lift, with an insight on how strength is holding through the cut or bulk. |
| **Photos** | Front, side and back progress photos with a side-by-side compare. Stored on the phone only, never uploaded or backed up. Tip: same spot, same light, same time of day. |

### 7.1 Weekly check-in
- Your expenditure is **measured**: average intake minus the energy implied by
  the trend-weight change, over a rolling 14–28 days. A formula
  (Mifflin-St Jeor) is used only for the first week.
- The target moves toward what that measured expenditure and your chosen rate
  call for, never by more than 120 kcal in a week.
- Two cases get their own screen:
  - losing much faster than asked, where muscle is at risk
  - a genuine stall

### 7.2 Streak
- **What keeps a day:** meals logged, plus either a workout or a planned rest
  day. Logging is what counts, not eating less.
- **Freezes:** one is earned every 7 kept days, up to 3 held, for sick days
  and travel.
- **Repair:** a missed day can be repaired until 23:59 the next day.
- **Pause:** the streak can be paused, for example while ill.
- A broken streak keeps the best run on record.

### 7.3 Awards (3D badges)
- **Streak:**
  - First week (7 days)
  - Two weeks (14)
  - One month strong (30)
  - Habit formed (66)
  - Full commitment (90)
  - Comeback
- **Food:**
  - First full day
  - 100 meals logged
  - Protein week
- **Training:**
  - First workout
  - 25 workouts
  - 10 personal bests
- **Monthly challenge:** train N times this month.
- Drag a badge to turn it over and see when it was earned. Badges can be shared.

---

## 8. Me

- **Goal and targets:** change the goal, rate, or macros by hand.
- **Units and language:**
  - follow the phone, or choose English, العربية or Español
  - Arabic switches the whole layout to right-to-left
- **Account** (optional, email code with no password):
  - **Backup and restore:** automatic when the app goes to the background, or
    on demand.
  - **Restore** a backup on a new phone.
  - **Photo logging** (AI, 10 a day).
  - **Delete account:** removes the account and its backup immediately.
- **Health data:**
  - Apple Health (iPhone) or Health Connect (Android).
  - **Reads:** body weight and steps.
  - **Writes:** workouts, water and weigh-ins.
  - Clear help if permission is refused or Health Connect isn't installed.
- **Your data:**
  - export everything
  - view the consents you gave
  - delete everything on the phone with one tap and one confirmation
- **Reminders:** each has its own on/off switch and editable times.
  - **Meals:** a nudge if a meal isn't logged by its time.
  - **Water:** nudges through the day.
  - **Workout:** a reminder on training days.
- **Safeguards:**
  - cheat meal allowance
  - calorie floor
- **Gymco Pro** (see §9).
- **About:**
  - Help & support
  - Privacy policy
  - Terms of use (on gymcoapp.com)

---

## 9. Plans

| | Free | Pro | Lifetime |
|---|---|---|---|
| Price | — | **€4.99 / month** or **€39.99 / year** | **€89 once** |
| What it adds | Everything to log and train | Coaching that adapts every week | All of Pro, paid once |

Pro features:
- adaptive targets and the weekly check-in
- strength tracked against your deficit
- volume per muscle and full history

The plan cards swipe, and a toggle switches monthly and yearly pricing.
**Gymco is in testing: nothing is for sale yet, and every Pro feature is
unlocked.**

---

## 10. Privacy and data

**Stays on the phone:**
- food log, workouts, routines, weigh-ins, measurements, targets, settings
- progress photos
- data read from Health

**With an account only:**
- your email
- one backup of the diary (photos excluded)
- a daily counter of AI scans

**AI estimates:** the photo or text goes through Gymco's server to Anthropic
for the estimate and is not kept. The AI model is Claude Haiku.

**Barcode and search:** the barcode or search words go to Open Food Facts,
with nothing that identifies you.

**Crash reports** (Firebase Crashlytics, once configured) contain only the
error and the phone model, never what you logged.

**Never:**
- ads or advertising trackers
- usage analytics
- selling data

Full policy: https://gymcoapp.com/privacy/

---

## 11. Behind the scenes

| Piece | Detail |
|---|---|
| App | Flutter (Riverpod, go_router), on-device SQLite database |
| Backend | Supabase: email-code auth, the backup table, a daily AI scan cap of 10, `food-photo` (AI estimate), `delete-account`, `admin-stats` |
| Builds | GitHub Actions: Android APK test build, unsigned iOS build, signed release to TestFlight and Google Play internal testing |
| Website | GitHub Pages from `site/`, on gymcoapp.com |
| Email | `support@gymcoapp.com` forwarded via ImprovMX |
| Admin | gymcoapp.com/admin, showing only totals:<br>• accounts, sign-ups, active accounts<br>• AI scans and their estimated cost<br>• backups and database size<br>• accounts that hit the scan cap, deletions |
| Mirror | Every push is copied to `iFynx/Gymco` (needs `MIRROR_TOKEN`) |
