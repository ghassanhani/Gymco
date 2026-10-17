# Gymco

Diet and training for lifters. Flutter, one codebase for iOS and Android, in English, Arabic (right to left) and Spanish. Built from the **Gymco — App Design** canvas (Volt edition).

## What works now

Every screen is drawn from the Volt prototype's own component kit (`lib/ui/kit`): its icons, cards, chips, sheets, keypad, week strip and tab bar, with the same sizes, radii and colours.

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

Progress is designed and comes next; its tab says so. Exercise names are English only for now; Arabic and Spanish names come with a translation pass.

## Run it

```sh
flutter pub get
flutter run          # on a connected phone or simulator
flutter test         # 77 tests
```

An iPhone needs a Mac with Xcode. Android needs Android Studio, or just a phone with USB debugging.

## Roadmap

1. ~~Core diet~~
2. ~~Training~~ (deload weeks still to come)
3. **Progress**: weigh-ins and trend chart, weekly check-in using the adaptive engine, streak and awards screens, cheat-meal planning screens
4. **AI logging** (Write, Voice, Photo, Eating out) on Claude Haiku via a Supabase Edge Function, with simple rules first and a daily cap
5. **Accounts and sync** (Supabase free tier), reminders, Apple Health / Health Connect, progress photos, large text

## Free stack

| Need | Choice | Cost |
|---|---|---|
| App | Flutter | free |
| On-phone data | SQLite (sqflite) | free |
| Food data | Open Food Facts + bundled USDA staples | free |
| Barcode | mobile_scanner | free |
| Fonts | Urbanist, Instrument Serif, IBM Plex Sans Arabic (OFL, bundled) | free |
| CI | GitHub Actions | free |
| Later: accounts and sync | Supabase free tier | free |

The only unavoidable costs come at publishing: Apple Developer $99/year, Google Play $25 once.

## Notes

- Icons are Material Rounded for now. The design uses the Thiqal icon set; swap it in once its license is confirmed.
- The bundled staple foods (`lib/data/seed_foods.dart`) carry USDA per-100 g values and English names only. Check the values before launch, and add Arabic and Spanish names.
