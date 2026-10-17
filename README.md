# Gymco

Diet and training for lifters. Flutter, one codebase for iOS and Android, in English, Arabic (right to left) and Spanish. Built from the **Gymco — App Design** canvas (Volt edition).

## What works now

Every screen is drawn from the Volt prototype's own component kit (`lib/ui/kit`): its icons, cards, chips, sheets, keypad, week strip and tab bar, with the same sizes, radii and colours.

### Phase 5: account, backup and photo logging

- **Account** (Me → Account): sign in with your email and a six-digit code, no password. Fully optional: without it the app is phone-only and says so.
- **Backup**: the whole diary (food log, weigh-ins, measurements, routines, workouts, saved meals, custom foods, favourites, settings) as one document in your account. It backs up by itself when you leave the app, at most every six hours, or on demand. Signing in on a new phone offers to restore it.
- **Photo**: photograph the plate (or pick a photo) and Claude Haiku names the foods it sees, marking the ones it is not sure of. You tap each to set the amount; it never guesses grams. 10 photos per account per day, counted on the server.
- **Delete account** removes the account and its backup; what is on the phone stays until you delete it under Your data.

### Phase 4a: write and say what you ate

- **Write**: type a meal the way you would say it ("200g chicken breast, 150g rice and 10g olive oil", "2 eggs with two slices of bread", "a scoop of whey") and it is read into foods with weights, then logged together. Grams, kilos, ounces and ml; counts, number words, halves and fractions; scoops, slices, spoons, cups. English, Arabic (Arabic digits, an attached "و", duals like "بيضتين") and Spanish.
- Rows with no amount are marked **assumed** and use a normal serving; tap any row to set grams. Foods the phone does not know get a Search button.
- **Voice**: hold the mic and say it; the phone's own speech recogniser writes the transcript, which goes through the same reader and can be edited.
- No model and no network: rules in `lib/domain/meal_text.dart`, so it is free and works offline.

### Phase 3: progress

- **Weight**: weigh-ins on a keypad, a smoothed trend line with the next four weeks projected, the weekly rate, change since start, weigh-in count.
- **Measure and strength**: waist log; each main lift's estimated 1RM and its change over eight weeks.
- **Weekly sets**: hard sets per muscle this week, secondary muscles counted as half, against the 10–20 band.
- **Weekly check-in**: expenditure measured from intake and trend weight (after 14 fully logged days), next week's target moved at most 120 kcal (carbs take the change), and its own screens for losing too fast and for a genuine stall, with honest options.
- **Streaks and awards**: a day counts when breakfast, lunch and dinner are logged and you train or rest as planned. Freezes, a commitment you choose (21 to 365 days), and medals for streaks, food and training. None is for eating less or losing weight.

### Design pass

- **Train is a day**: the week strip walks the plan, which slides when a session is missed (the block keeps its order, not its dates). Today's session shows its exercises with a start button on each, so one exercise can be done on its own. Rest days, closed days and days ahead each say what they are.
- **Templates**: Upper / Lower 4 days, Push / Pull / Legs 6 days, Full body 3 days, with weekly volume already inside 10–20 sets a muscle.
- **Library and builder**: two folders, routine cards, a menu to start, edit, duplicate or delete. The builder sets a weekday (and moves a clash to any day), sets, rep range and rest, and shows what the routine does to weekly sets per muscle.
- **Live workout**: the prototype's set grid (set, previous, kg, reps, RIR, tick), numbers typed on a keypad, a typed weight filling the sets below, set types, a rest timer per exercise, supersets, notes, and a resume bar that follows you around the app.
- **Summary and exercise pages**: duration, volume, hard sets, best set of each exercise with PRs, where the week stands, save as routine, share. Each exercise has its estimated 1RM over six months, best 5 and 8 rep sets, sets per week, how to do it and its history.
- **Diet**: meal detail under the tabs (save as a meal, copy to tomorrow), serving editor with keypad, favourites and save as custom, My meals and Custom shelves, a five-goal onboarding with a 12-week projection and manual macros.
- **Your data**: export everything as CSV and JSON, see recorded consent, delete everything (GDPR).

### Phase 2: training

- **Exercise library**: 876 exercises from free-exercise-db (public domain) bundled in the app, with search, muscle filters, instructions and photos (downloaded on first view, then kept on the phone).
- **Routines**: build, edit and delete. Save stays off until there's a name and an exercise, and duplicate names are refused.
- **Live workout**: weight, reps and set type per set (warm-up, working, failure, drop), last time's numbers shown and pre-filled, a rest timer that starts on each ticked set (adjust ±15 s or skip), and live time, volume and set count. The workout is saved on the phone after every change, so closing the app loses nothing.
- **Finish**: unticked sets need confirming and aren't saved. A summary shows new bests (estimated 1RM). History lists past workouts.

### Phase 1: core diet

- **Onboarding**: goal, body, activity, rate (capped at 1 %/week, warning above 0.85 %), starting targets from Mifflin-St Jeor, with the no-numbers offer.
- **Today**: calorie ring and macro bars (over and under both read neutral), four meals, an empty-day prompt, and habit tracking in no-numbers mode.
- **Food logging**: search runs against the phone's database first, then Open Food Facts. Online finds are saved for offline use. Barcode scanning, amount entry with live kcal and macros, swipe to delete, repeat yesterday's meal. An unknown barcode links to adding it on Open Food Facts.
- **Me**: language (phone, English, العربية, Español), no-numbers mode (leaving it needs a confirmation), cheat-meal allowance, redo targets.
- **Rules engine** (`lib/domain`, fully tested): adaptive expenditure over a 14–28 day window that drops incomplete and free-cheat days, ±120 kcal check-in cap, trend weight, stall detection, streaks with freezes (1 per 7 kept days, max 3) and a repair window, banked cheat meals (protein untouched, 1,700 floor, steep above 300/day), set types and volume.

Exercise names are English only for now; Arabic and Spanish names come with a translation pass.

## Run it

```sh
flutter pub get
flutter run          # on a connected phone or simulator
flutter test         # 113 tests
```

An iPhone needs a Mac with Xcode. Android needs Android Studio, or just a phone with USB debugging.

## Cloud setup (Supabase)

The cloud part is in `supabase/`: one migration (`backups`, `ai_usage` with row level security, and the scan allowance functions only the server can call) and two Edge Functions, `food-photo` and `delete-account`.

1. Create a Supabase project (free tier), then from this folder: `supabase link --project-ref <ref>`, `supabase db push`, `supabase functions deploy food-photo delete-account`.
2. `supabase secrets set ANTHROPIC_API_KEY=...` — the photo function's key. It never reaches the app.
3. Authentication → Email: keep email sign-in on, and change the Magic Link template to show the code, e.g. `Your Gymco code: {{ .Token }}`. Supabase's built-in mailer sends only a few emails an hour; add your own SMTP before launch.
4. Build the app with the project's URL and publishable key:
   `flutter run --dart-define=SUPABASE_URL=https://<ref>.supabase.co --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_...`

Cost: Supabase free tier; Claude Haiku 5.5 is about $0.10 per million input tokens, so a photo costs well under a tenth of a cent and the 10-a-day cap bounds it per user.

## Roadmap

1. ~~Core diet~~
2. ~~Training~~ (deload weeks still to come)
3. ~~Progress~~ (progress photos and cheat-meal planning screens still to come)
4. ~~AI logging~~: Write and Voice on rules on the phone; Photo on Claude Haiku via a Supabase Edge Function, 10 a day. Eating out still to come
5. ~~Accounts and backup~~ (Supabase free tier). Next: reminders, Apple Health / Health Connect, progress photos, large text, food names in Arabic and Spanish

## Free stack

| Need | Choice | Cost |
|---|---|---|
| App | Flutter | free |
| On-phone data | SQLite (sqflite) | free |
| Food data | Open Food Facts + bundled USDA staples | free |
| Barcode | mobile_scanner | free |
| Dictation | speech_to_text (the phone's own recogniser) | free |
| Accounts, backup | Supabase (email code sign-in, Postgres, Edge Functions) | free tier |
| Photo logging | Claude Haiku 5.5, 10 photos a day per account | well under $0.001 a photo |
| Fonts | Urbanist, Instrument Serif, IBM Plex Sans Arabic (OFL, bundled) | free |
| CI | GitHub Actions | free |
| Later: accounts and sync | Supabase free tier | free |

The only unavoidable costs come at publishing: Apple Developer $99/year, Google Play $25 once.

## Notes

- Icons are Material Rounded for now. The design uses the Thiqal icon set; swap it in once its license is confirmed.
- The bundled staple foods (`lib/data/seed_foods.dart`) carry USDA per-100 g values and English names only. Check the values before launch, and add Arabic and Spanish names.
