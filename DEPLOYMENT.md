# ExLog — Android Deployment Guide

This covers two separate things:

1. **Running the app on a physical Android device** (for testing — no Play Store involved).
2. **Publishing to the Google Play Store** (release signing, Play Console setup, the SMS-permission declaration this app specifically needs, and rollout).

Project specifics used throughout this doc (confirmed from the current codebase):

| | |
|---|---|
| Package name (`applicationId`) | `in.co.explog.exlog` |
| Firebase project | `explog-dec02` (shared with the iOS app — do not create a second project) |
| Auth method | Email/password only (no Google/Apple Sign-In, so no OAuth consent screen or SHA fingerprint registration needed for sign-in) |
| Current version | `1.0.0+1` (`pubspec.yaml` → versionName `1.0.0`, versionCode `1`) |
| Privacy Policy | already hosted: `https://amitgaurav.online/exlog/privacy-policy` |
| Terms of Service | already hosted: `https://amitgaurav.online/exlog/terms-of-service` |
| Special permission | `RECEIVE_SMS` (Android-only SMS auto-detect feature) — **requires Play Console's Permissions Declaration Form**, see below |

---

## Part A — Install on a physical Android device (testing, no Play Store)

### 1. Prepare the phone
1. Settings → About phone → tap "Build number" 7 times to unlock Developer Options.
2. Settings → Developer Options → enable **USB debugging**.
3. Connect the phone to your Mac via USB. Accept the "Allow USB debugging?" prompt on the phone.

### 2. Confirm Flutter sees it
```bash
flutter devices
```
Your phone should appear (not just the emulator). If it doesn't, check the USB cable/port and that USB debugging is really on.

### 3. Run directly (fastest, for active development)
```bash
cd /Users/amitgaurav/workspace-flutter/exlog_flutter
flutter run -d <device-id>
```
This installs a debug build with hot reload. Good for iterating, but debug builds are larger/slower and use the debug keystore.

### 4. Or install a standalone APK (closer to how a real user gets it)
```bash
flutter build apk --release   # requires release signing set up — see Part B first
# or, to test without setting up release signing yet:
flutter build apk --debug
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```
The `--debug` APK works fine for functional testing (including the SMS auto-detect feature) but is signed with the debug key — **never distribute a debug-signed APK to real users**, and it can't be uploaded to Play Console.

### 5. Testing the SMS features on a real device
- Auto Import (paste SMS): works identically to the emulator — no special setup.
- Android auto-detect: Settings → App Settings → toggle "Auto-detect from SMS" → grant the SMS permission when prompted. On a real device you can test with an actual incoming bank/UPI SMS instead of `adb emu sms send`.

---

## Part B — Publishing to Google Play Store

### Step 1 — Assets you still need before submitting

- **App icon** ✅ **done** — replaced with the real ExLog brand icon (brain/gear/rupee mark) at all 5 launcher densities (`android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/ic_launcher.png`), sourced from `~/Downloads/AppIcons/android/mipmap-*/ExLog_Launcher_iOS.png` and verified live on-device. The 512×512 Play Console store-listing icon is saved at `store_assets/playstore-icon-512.png` in this repo (from `~/Downloads/AppIcons/playstore.png`) — upload that file directly in Play Console's store listing "App icon" field.
  - Note: no adaptive-icon layers (`mipmap-anydpi-v26/ic_launcher.xml` with separate foreground/background) exist yet — the app currently ships a flat legacy icon only, which Android auto-masks per-launcher (confirmed fine visually on Android's default circular mask). If you want an adaptive icon later (a proper safe-zone foreground on a separate background layer, so it doesn't get double-rounded/clipped oddly on squircle launchers), that needs new foreground/background source layers from whoever designed the icon — the current source assets don't include them.

Still open — **do these before your first upload**:

- **Feature graphic**: 1024×500 PNG/JPG banner for the Play Store listing — doesn't exist yet, needs to be designed.
- **Screenshots**: at least 2 phone screenshots (Play Console recommends 4–8) — you already have the `iPhone-17-Pro` reference set used throughout this project's UI/UX work, but Play Store wants **Android** screenshots; capture fresh ones from this app running on an Android device/emulator (`adb exec-out screencap -p > screenshot.png`, the same technique used throughout this project's verification steps).
- **Short description** (max 80 chars) and **full description** (max 4000 chars) for the store listing — not yet drafted.

### Step 2 — Decide on versioning

`pubspec.yaml` currently has `version: 1.0.0+1` (`versionName+versionCode`). Play Store requires every uploaded build to have a **strictly increasing versionCode**. Bump the `+N` suffix for every new upload (`1.0.0+1` → `1.0.0+2` → ... ; bump `1.0.0` itself for user-facing version changes).

### Step 3 — Generate a release keystore

This is a **one-time, irreversible** step — losing this keystore means you can never update the app again under the same Play Store listing (Play App Signing mitigates this somewhat, see note below, but you still need this "upload key"). Store the `.jks` file and its passwords somewhere durable (password manager + a backup copy), **not just on this machine**.

```bash
cd /Users/amitgaurav/workspace-flutter/exlog_flutter/android
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```
`keytool` will prompt for a keystore password, your name/org details, and a key password (you can reuse the keystore password for the key password). Answer "yes" to confirm.

Then create `android/key.properties` (already gitignored — confirmed in `android/.gitignore`, never gets committed):
```properties
storePassword=<the keystore password you chose>
keyPassword=<the key password you chose>
keyAlias=upload
storeFile=upload-keystore.jks
```

The project's `android/app/build.gradle.kts` has already been wired to read this file automatically — as soon as `key.properties` exists, `flutter build appbundle`/`flutter build apk --release` will sign with it instead of the debug key. No further Gradle changes needed.

> **Play App Signing**: when you first create the app in Play Console and upload this upload-key-signed bundle, opt into "Play App Signing" (default for new apps). Google then re-signs the app for distribution with its own key, and your upload key only needs to be kept for future uploads — if you ever lose it, Google support can help you reset it, which is not possible without Play App Signing.

### Step 4 — Verify Firebase is happy with the release build

The app already shares the `explog-dec02` Firebase project via `android/app/google-services.json` (already present, confirmed). Since this app only uses email/password auth (no Google Sign-In), you do **not** need to register the release keystore's SHA-1/SHA-256 in Firebase Console for auth to keep working.

Still worth doing anyway (enables Play Integrity/App Check and Dynamic Links if you add them later):
```bash
cd android && keytool -list -v -keystore upload-keystore.jks -alias upload
```
Copy the SHA-1/SHA-256 shown, then in [Firebase Console](https://console.firebase.google.com/project/explog-dec02/settings/general) → Project Settings → Your Android app → "Add fingerprint".

### Step 5 — Build the release App Bundle

Play Store requires the **Android App Bundle** format (`.aab`), not a raw APK, for new app submissions:
```bash
cd /Users/amitgaurav/workspace-flutter/exlog_flutter
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`. This is what you upload to Play Console.

(For sideload-testing a release-signed build directly on a device instead, `flutter build apk --release` also now uses the same signing config.)

### Step 6 — Create the app in Google Play Console

1. Go to [play.google.com/console](https://play.google.com/console) (requires a one-time $25 Google Play Developer account registration if you don't already have one).
2. "Create app" → app name "ExLog" → default language → App/Game → Free/Paid → accept declarations.

### Step 7 — Complete the required Play Console sections

Play Console won't let you release to production until every item below is green. Do them in this order:

**App content:**
- **Privacy Policy** — paste `https://amitgaurav.online/exlog/privacy-policy` (already hosted, confirmed).
- **App access** — since the app requires sign-in, provide a test account (email/password) so Google's reviewers can log in. Create a dedicated test account in the shared Firebase project rather than using a real user's credentials.
- **Ads** — declare "No ads" (confirmed no ad SDKs in `pubspec.yaml`).
- **Content rating questionnaire** — answer honestly; a finance-tracking app with no violent/mature content typically rates "Everyone".
- **Target audience** — select an adult age range (13+ or 18+ as appropriate); this is a personal-finance app, not designed for children.
- **Data safety form** — this is the important one given what this app collects. At minimum, declare:
  - **Financial info** (transaction amounts/categories) — collected, linked to user identity, used for app functionality, not shared with third parties (unless the user enables the AI SMS Parser with their own API key, in which case SMS text is sent to their chosen third-party LLM provider — disclose this).
  - **SMS or MMS** — collected on-device (Android auto-detect feature), used for app functionality only, not shared. This is scrutinized closely by Google's review team; be precise and consistent between this form and the Permissions Declaration Form below.
  - **Personal info** (email) — collected for account creation.
  - Declare data is encrypted in transit (yes, Firebase uses TLS) and that users can request deletion (yes — account deletion is already implemented, confirmed in `auth_repository_impl.dart`/`app_settings_page.dart`).
- **Government apps** — No (unless applicable).

**Permissions Declaration Form (specific to this app's `RECEIVE_SMS` permission):**
Play Console flags `RECEIVE_SMS`/`READ_SMS` as a "sensitive permission" and requires a separate declaration before you can publish:
1. Play Console → App content → "Permissions declaration form" (or it will prompt automatically once it detects the manifest permission).
2. Select the core use case: **"Automatically identify and log a user's SMS-based financial transactions"** (personal finance / expense tracking is a Google-recognized approved category for this permission — apps like Walnut and Fold have shipped this exact feature).
3. Explain concretely: *"ExLog is an expense-tracking app. With explicit user opt-in (a Settings toggle, off by default), it reads incoming SMS to auto-detect bank/UPI transaction messages and stages them for the user to manually approve or reject before any transaction is created. The app does not use READ_SMS (no inbox history scan) — only RECEIVE_SMS for messages arriving after the feature is enabled. Non-financial SMS never leaves the device (filtered on-device before any network call)."*
4. Attach/point to a short demo (Google sometimes asks for a video showing the permission's in-app purpose) — a short screen recording of Settings → toggle on → permission prompt → receiving a test SMS → approve/reject flow covers this well.
5. This declaration is reviewed by a human team and can take longer than a typical app review (sometimes several days) — factor this into your launch timeline, and expect it on **every** future release too if the permission stays in the manifest.

**Store listing:**
- App icon (512×512) — ready: `store_assets/playstore-icon-512.png`.
- Feature graphic (1024×500) — still needed, see Step 1.
- Screenshots (2–8, phone) — from Step 1.
- Short description (≤80 chars), e.g. *"Track expenses, auto-import bank SMS, and manage your money — ExLog."*
- Full description (≤4000 chars) — cover: manual transaction tracking, categories, reminders, SMS-based auto-import (paste + Android auto-detect), analytics/dashboard, CSV export/import, optional AI-assisted SMS parsing (mention the user supplies their own API key).
- Contact email/website — use the same domain the privacy policy is hosted on.

**Pricing & distribution:**
- Countries: choose where to distribute (India, given the app's INR/UPI/Indian-bank focus, is the obvious primary market).
- Confirm "Contains ads" = No, and complete the US export laws / content guidelines declarations.

### Step 8 — Testing tracks before production

Don't go straight to production. Play Console's testing tracks, in order:
1. **Internal testing** (up to 100 testers, no review wait) — upload the `.aab` here first, add your own email + a few trusted testers, sanity-check the whole app including SMS auto-detect on real devices.
2. **Closed testing** (larger group, requires basic review) — optional but recommended for a wider beta before public launch, especially to get real-world signal on the SMS parsing accuracy across different banks.
3. **Production** — once internal/closed testing looks good and the Permissions Declaration + Data Safety form are approved, promote the build to production. New apps typically get a slower, staged rollout by default (e.g. 20% → 50% → 100%) — keep an eye on the Play Console crash/ANR dashboards during rollout before increasing the percentage.

### Step 9 — Post-launch

- Monitor Play Console's **Android vitals** (crashes, ANRs) for the first few days after each release.
- Every future update: bump `versionCode` in `pubspec.yaml`, rebuild the `.aab` with the same `key.properties`/keystore, upload to Play Console, and — if you ever touch `AndroidManifest.xml`'s SMS permission again — expect the Permissions Declaration to be re-reviewed.
- Keep `upload-keystore.jks` and `key.properties`'s passwords backed up outside this machine (e.g. a password manager). If they're lost and Play App Signing wasn't enabled at first upload, you cannot publish updates to this app listing ever again.

---

## Quick reference — commands used in this doc

```bash
# Physical device testing
flutter devices
flutter run -d <device-id>
flutter build apk --debug && adb install -r build/app/outputs/flutter-apk/app-debug.apk

# Release keystore (one-time)
cd android && keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Release build for Play Store
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab

# Check release keystore fingerprints (for optional Firebase registration)
keytool -list -v -keystore android/upload-keystore.jks -alias upload
```
