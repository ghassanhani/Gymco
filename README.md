# Gymco

**Diet and training for lifters: log a meal in seconds, train to a plan, and keep a streak that rewards consistency, not starvation.**

<!-- SCREENSHOT PLACEHOLDER: add docs/screenshots/hero.png (Today, Live workout and Progress side by side), then uncomment:
<p align="center">
  <img src="docs/screenshots/hero.png" alt="Gymco app screens" width="820">
</p>
-->

🔗 **Live:** [gymcoapp.com](https://gymcoapp.com) · 📱 iOS & Android (TestFlight / Play internal testing) · 🌍 English · العربية · Español

---

## The problem

Lifters end up juggling two apps: one for food and one for training. Most food trackers make logging slow (search, scroll, guess grams), reward eating less over eating well, and treat Arabic as a mirrored afterthought. Training apps rarely know what you ate, and none of them adjust your targets based on what your body actually did.

## What Gymco does

- **Logging that keeps up with you.** You can type or say a meal the way you'd describe it ("200g chicken, 150g rice and a spoon of olive oil"), scan a barcode, or photograph the plate. Text and voice are parsed on the phone, offline, in all three languages.
- **Training as a day, not a spreadsheet.** A week strip walks your plan, today's session sits on one card, and the live workout grid (set · previous · kg · reps · RIR) is driven by a custom keypad.
- **Targets that adapt.** A weekly check-in estimates real expenditure from intake and trend weight, and it never moves your target by more than 120 kcal at a time.
- **Streaks that are healthy by design.** A day counts when you log your meals and train or rest as planned. Freezes, a commitment you choose, and a banked cheat-meal system. No award is ever given for eating less.

## Design decisions

| Decision | Why |
|---|---|
| **One component kit drawn from the prototype** (`lib/ui/kit`) | Every screen uses the same icons, cards, chips, sheets, keypad and tab bar as the Volt design prototype, so design and code don't drift. Design changes are recorded back in [`docs/DESIGN-CHANGES.md`](docs/DESIGN-CHANGES.md). |
| **RTL designed in, not mirrored** | IBM Plex Sans Arabic alongside Urbanist. The serif accent word becomes bold lime sans in Arabic (Instrument Serif has no Arabic glyphs). The meal parser understands Arabic digits, the attached "و" and duals like "بيضتين". |
| **Neutral over/under states** | Going over or under on calorie and macro bars reads neutral, never red. The app coaches and doesn't shame. |
| **The AI never guesses grams** | Photo logging (Claude Haiku) names the foods it sees and flags the ones it's unsure of. You set the amounts. Rules beat models where rules are enough: text and voice parsing runs free and offline. |
| **Phone-first, account optional** | The diary lives on the device (SQLite). Sign-in is a passwordless six-digit code, used only for backup. Export, consent records and delete-everything are built in (GDPR). |
| **Honest edge cases** | Losing too fast and genuine stalls each get their own screens with real options, instead of a generic warning. |
| **Volume you can see** | Hard sets per muscle are counted weekly (secondary muscles count as half) against a 10–20 band, including while you build a routine. |

## Stack

| Layer | Tech |
|---|---|
| App | **Flutter** (Dart), Riverpod, go_router, sqflite, Flutter l10n (EN / AR / ES) |
| Food data | Open Food Facts + bundled USDA staples, `mobile_scanner` for barcodes, on-device `speech_to_text` |
| Backend | **Supabase**: Postgres with row-level security, email-code auth, and Edge Functions (TypeScript/Deno) for photo logging, backup, support, waitlist and admin |
| AI | Claude Haiku via a server-side Edge Function, capped at 10 photos a day per account |
| Platform | Firebase Crashlytics & FCM, Health / Health Connect, local notifications |
| Web | Trilingual landing page + an admin **Control Center** (vanilla JS, MFA-protected) on GitHub Pages |
| CI/CD | GitHub Actions: tests, golden screenshot tests, APK on every push, TestFlight + Play internal release workflow |

## Repo tour

```
lib/domain     rules engine: expenditure, check-ins, streaks, cheat meals, volume (fully unit-tested)
lib/ui/kit     the design system: theme tokens (Volt), components, icons, motion
lib/ui/…       Today, Food, Train, Progress, Me, Onboarding
site/          landing page (gymcoapp.com) and Control Center (/admin)
supabase/      migrations, Edge Functions, email templates, SQL tests
test/          unit, widget, golden-screenshot and site tests
```

## Run it

```sh
flutter pub get
flutter run      # phone or simulator
flutter test
```

Setup for the cloud, release and Supabase lives in **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)**.

---

Designed and built by **Ghassan Hani**, Senior Product Designer · [gsanhani.com](https://gsanhani.com) · [LinkedIn](https://www.linkedin.com/in/ghassanhani0/)
