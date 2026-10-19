# Releasing Gymco to the stores

The **Release** workflow (Actions → Release → Run workflow) builds signed apps and
sends them to **TestFlight** (iPhone) and **Google Play internal testing**
(Android). It needs a one-time setup in each store and a few repository secrets
(GitHub → Settings → Secrets and variables → Actions → New repository secret).
Secrets never appear in the code or in build logs.

App ID on both stores: `app.gymco.gymco`

## iPhone — TestFlight

1. **Create the app** in App Store Connect → Apps → + → New App.
   Platform iOS, name Gymco, bundle ID `app.gymco.gymco` (register it under
   Certificates, Identifiers & Profiles → Identifiers first if it is not in the
   list, and tick **HealthKit** there).
2. **Make an API key**: App Store Connect → Users and Access → Integrations →
   App Store Connect API → Team Keys → +. Role **App Manager**. Download the
   `.p8` file (you can only download it once).
3. **Add these secrets**:
   - `APPLE_TEAM_ID` — 10 characters, from developer.apple.com → Membership details
   - `ASC_KEY_ID` — the key's ID, shown next to it
   - `ASC_ISSUER_ID` — shown above the keys list
   - `ASC_KEY_P8` — open the `.p8` file in a text editor and paste all of it,
     including the BEGIN and END lines
4. Run **Release** with platform `ios`. In about 15 minutes the build appears
   in App Store Connect → TestFlight. Add yourself under **Internal Testing**,
   then install the **TestFlight** app on the iPhone.

## Android — Google Play internal testing

1. **Make an upload key** once, on any computer with Java (keep the file and
   both passwords somewhere safe — you need them for every update):

   ```
   keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. **Add these secrets**:
   - `ANDROID_KEYSTORE_BASE64` — the file as text: `base64 -i upload.jks` (Mac) or
     `base64 -w0 upload.jks` (Linux); on Windows,
     `[Convert]::ToBase64String([IO.File]::ReadAllBytes("upload.jks"))` in PowerShell
   - `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_PASSWORD` — the passwords you chose
   - `ANDROID_KEY_ALIAS` — `upload`
3. **Create the app** in Play Console → Create app (name Gymco, app, free).
4. Run **Release** with platform `android`, download the `gymco-android-aab`
   artifact from the run, and upload it **by hand once**: Play Console →
   Testing → Internal testing → Create new release. Google requires the first
   upload to be manual. Add testers by email under the Testers tab.
5. **Let the workflow upload from now on**: Google Cloud Console → create a
   service account → Keys → Add key → JSON. In Play Console → Users and
   permissions, invite the service account's email with **Release to testing
   tracks** for Gymco. Save the JSON file's contents as the secret
   `PLAY_SERVICE_ACCOUNT_JSON`.

After that, every **Release** run sends a new build to both testing tracks.

## Store listing links (gymcoapp.com)

| Field | URL |
|---|---|
| Marketing / website | https://gymcoapp.com |
| Support URL | https://gymcoapp.com/support/ |
| Privacy policy URL | https://gymcoapp.com/privacy/ |
| Terms of use (EULA) | https://gymcoapp.com/terms/ |
| Google Play: delete account URL | https://gymcoapp.com/delete-account/ |

The site lives in `site/` and deploys with `.github/workflows/site.yml` (GitHub Pages).
