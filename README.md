# Gymco

Diet and training for lifters. Flutter, one codebase for iOS and Android, in English, Arabic (right to left) and Spanish. Built from the **Gymco — App Design** canvas (Volt edition).

## What works now

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
flutter test         # 55 tests
```

An iPhone needs a Mac with Xcode. Android needs Android Studio, or just a phone with USB debugging.

## Roadmap

1. ~~Core diet~~
2. ~~Training~~ (supersets and deload weeks still to come)
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
