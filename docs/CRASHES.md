# Crash reports (Firebase Crashlytics, free)

Release and test builds send crashes to Crashlytics once these six GitHub
secrets are set. Without them the app runs exactly as before, with no reports.

## 1. Create the Firebase project

1. Go to https://console.firebase.google.com and click **Create a project**.
   Name it `Gymco`. Google Analytics: you can turn it off.
2. On the project page, click **Add app → Android**.
   - Package name: `app.gymco.gymco`
   - Click **Register app**, download `google-services.json`, then skip the
     remaining steps (the app does not need the file in the repo).
3. Click **Add app → iOS**.
   - Bundle ID: `app.gymco.gymco`
   - Click **Register app**, download `GoogleService-Info.plist`, then skip
     the remaining steps.
4. In the left menu open **Crashlytics** and click **Enable** if asked.

## 2. Copy the values into GitHub secrets

Gymco repo → **Settings → Secrets and variables → Actions → New repository secret**.

| Secret | Where to find it |
|---|---|
| `FIREBASE_PROJECT_ID` | `google-services.json` → `project_info.project_id` |
| `FIREBASE_SENDER_ID` | `google-services.json` → `project_info.project_number` |
| `FIREBASE_ANDROID_API_KEY` | `google-services.json` → `client[0].api_key[0].current_key` |
| `FIREBASE_ANDROID_APP_ID` | `google-services.json` → `client[0].client_info.mobilesdk_app_id` |
| `FIREBASE_IOS_API_KEY` | `GoogleService-Info.plist` → `API_KEY` |
| `FIREBASE_IOS_APP_ID` | `GoogleService-Info.plist` → `GOOGLE_APP_ID` |

All six are also shown under Firebase **Project settings → General → Your apps**.

## 3. Check it works

Run a new build (any push to main, or **Actions → Release**), install it, and
open the app once. Crashlytics shows the app as connected after the first
launch; the first crash appears within a few minutes.

## What is sent

Only the error, its stack trace, and the phone model and OS version. Nothing
the user logs (food, weight, workouts, photos) is ever included. Debug builds
never send reports.
