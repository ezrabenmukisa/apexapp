# Firebase setup

How to configure Firebase for the Apex app (`com.apex.app`, Firebase project **`apex-9fcb6`**) so all three sign-in methods work: Google, phone and email.

## What is already done

| Item | State |
|---|---|
| Android app `com.apex.app` | Registered (`1:914541790823:android:d2f4765b9b7949586bf6c2`) |
| iOS app `com.apex.app` | Registered (`1:914541790823:ios:db73b412afd89d2b6bf6c2`) |
| `lib/firebase_options.dart`, `android/app/google-services.json` | Generated for the apps above |
| Android SHA fingerprints | Team debug key and release upload key are both registered (see [Signing keys](#signing-keys)) |
| Old `com.example.app` apps | Still listed in the console and unused. Safe to delete (Project settings → Your apps). |

Everything below happens in the [Firebase console](https://console.firebase.google.com/project/apex-9fcb6) unless it says otherwise.

---

## 1. Tools (once per machine)

```sh
flutter --version          # must be ≥ 3.47 (Dart ≥ 3.12)
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"   # add to your shell profile
```

## 2. Turn on the sign-in providers

Go to **Build → Authentication → Get started** (first time only), then open the **Sign-in method** tab.

### Email/Password
1. **Add new provider → Email/Password.**
2. Turn on **Email/Password**. Leave **Email link (passwordless sign-in)** off; the app uses passwords.
3. **Save.**

### Google
1. **Add new provider → Google**, then turn it on.
2. **Project support email:** choose a team address. Users see it on the consent screen.
3. **Save.** Firebase now creates the OAuth clients that Google sign-in needs.

### Phone
1. **Add new provider → Phone**, then turn it on.
2. Open **Phone numbers for testing** and add at least one fake number with a fixed code, e.g. `+256 700 000001` → `123456`. Test numbers never send a real SMS, so use them during development and demos.
3. **Save.**
4. **SMS region policy** (Authentication → Settings): allow at least Uganda (UG) plus the countries owners live in (e.g. GB, US). Alternatively leave it unrestricted.
5. **Billing:** Firebase requires the **Blaze (pay-as-you-go)** plan to send *real* SMS codes. Test numbers work on the free Spark plan. If real codes never arrive, check **Usage and billing**.

### Account linking
**Authentication → Settings → User account linking**: keep **Link accounts that use the same email** (the default). Someone who signs in with Google and later with email/password under the same address then stays one Firebase user, and therefore one Apex user. If two methods conflict, the app shows *"This email already signs in another way. Use that method instead."*

## 3. Regenerate the app config (required after enabling Google)

Turning on Google adds an OAuth web client to the project. The Android app reads it from `google-services.json` (it becomes the `default_web_client_id` resource), so pull the config again from the `apexapp/` directory:

```sh
flutterfire configure --project=apex-9fcb6 --platforms=android,ios \
  --android-package-name=com.apex.app --ios-bundle-id=com.apex.app --yes
```

Check that it worked: `android/app/google-services.json` should now contain an `oauth_client` entry with `"client_type": 3`. Commit the updated `google-services.json` and `lib/firebase_options.dart`. They are not secrets; they identify the app, not an account.

## 4. Android

Nothing else is needed on Android beyond the [signing keys](#signing-keys). Optionally, to make phone auth smoother:

- In [Google Cloud console](https://console.cloud.google.com/apis/library/playintegrity.googleapis.com?project=apex-9fcb6), **enable the Play Integrity API** for `apex-9fcb6`. Firebase uses it to verify the app silently; without it, users see a reCAPTCHA browser page before the SMS is sent.

## 5. iOS (needs a Mac and an Apple Developer account)

1. **Download the iOS config.** Project settings → Your apps → *iOS com.apex.app* → download **GoogleService-Info.plist**. You only need two values from it: `CLIENT_ID` and `REVERSED_CLIENT_ID`. You don't have to add the file to Xcode, because the app reads `firebase_options.dart`.
2. **Google sign-in.** Add to `ios/Runner/Info.plist`:
   ```xml
   <key>GIDClientID</key>
   <string><!-- CLIENT_ID from GoogleService-Info.plist --></string>
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string><!-- REVERSED_CLIENT_ID --></string>
         <!-- Phone auth reCAPTCHA fallback: the iOS app ID with ':' replaced by '-' -->
         <string>app-1-914541790823-ios-db73b412afd89d2b6bf6c2</string>
       </array>
     </dict>
   </array>
   ```
3. **Phone auth (silent push).**
   - Apple Developer → Keys → create an **APNs key** (.p8). Note the Key ID and your Team ID.
   - Firebase → Project settings → **Cloud Messaging** → *Apple app configuration* → upload the APNs key.
   - Xcode → Runner target → *Signing & Capabilities* → add **Push Notifications**, and add **Background Modes** with **Remote notifications** ticked.
4. Set the bundle identifier in Xcode to `com.apex.app` (already set in the project) and choose your team.

## Signing keys

The app signs Android builds with **shared team keys** instead of each developer's personal debug key. Everyone's builds then have the same SHA fingerprints, and Firebase needs them registered only once.

| File (in `android/`, gitignored) | Purpose | Who gets it |
|---|---|---|
| `keystore/apex-debug.jks` | Signs debug builds (`flutter run`) | Every teammate |
| `keystore/apex-upload.jks` | Signs release builds and Play Store uploads | Only whoever publishes |
| `key.properties` | Paths and passwords for both | Teammates get a copy with **only the debug lines** |

Fingerprints, all registered in Firebase:

| Key | SHA-1 | SHA-256 |
|---|---|---|
| Team debug | `BF:56:C7:F7:EE:1D:74:28:26:F7:23:DC:7B:E7:72:3B:AA:EA:58:F7` | `E2:D5:1E:9D:F6:18:D6:13:C7:12:56:94:A8:F7:68:14:E5:13:1B:FF:C6:97:2D:03:FF:83:F8:CC:46:14:E0:8F` |
| Release upload | `22:44:1D:CF:AC:FD:93:FB:BD:CE:76:96:B1:8C:7F:80:AB:18:09:BD` | `8E:0A:01:5A:B0:15:31:4E:6D:15:F8:83:D2:05:27:FB:C2:A5:DC:C7:05:D6:1A:02:A0:90:53:6C:26:39:C2:82` |

Rules:
- **The repo is public. Never commit `key.properties` or any `.jks`.** `android/.gitignore` already excludes them; never use `git add -f` on them.
- Share the debug keystore and its `key.properties` lines over a private channel (password manager, DM). Do not use the GitHub repo or a group chat that others can join.
- **Back up `apex-upload.jks` and its password** in a password manager. If it's lost, Play Console can reset the upload key, but that takes days.
- If a teammate builds without `key.properties`, Gradle falls back to their personal debug key, and Google/phone sign-in will fail for them until they get the shared key.
- **Play Store:** after the first upload, Play re-signs the app with Google's *app signing key*. Copy its SHA-1 and SHA-256 from **Play Console → Test and release → App integrity → App signing**, and add them in Firebase → Project settings → *Android com.apex.app* → **Add fingerprint**. Without them, sign-in breaks in builds installed from the Play Store.

To check which key signed an APK:
```sh
$ANDROID_HOME/build-tools/<version>/apksigner verify --print-certs build/app/outputs/flutter-apk/app-debug.apk
```

## 6. Verify

1. `cp .env.example .env` (first time only), then `flutter run` on an Android device or emulator. Sign-in uses the live API at apex.pntr.dev; other features use the in-app mock until their endpoints ship.
2. Try each option on *Sign in to Apex*:
   - **Google:** the account sheet appears, then you land on Complete Profile with your name prefilled.
   - **Phone:** enter a test number from step 2, then its fixed code, then Complete Profile with the phone prefilled.
   - **Email:** *Create an account*, then Complete Profile.
3. Firebase → **Authentication → Users**: each sign-in appears with its provider icon.
4. In the debug console, look for `appLogger` output: the startup line, bloc events and any mapped failures.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Google: *"Google sign-in isn't set up for this app yet"* / `clientConfigurationError` | `google-services.json` has no web OAuth client | Enable Google (step 2), then redo step 3 |
| Google: `ApiException: 10` / `DEVELOPER_ERROR` | The signing SHA isn't registered | Build with the shared debug key, or add your SHA in Firebase |
| Phone: `app-not-authorized` / `invalid-app-credential` / `missing-client-identifier` | SHA not registered, or Play Integrity can't verify the app | Check the SHAs; enable the Play Integrity API (step 4) |
| Phone: `quota-exceeded` / no SMS arrives | SMS quota reached, project on the Spark plan, or region blocked | Use a test number; check billing and the SMS region policy |
| Email: `operation-not-allowed` | Email/Password provider is off | Step 2 |
| Works for you but not a teammate | They're signing with their own debug key | Give them `apex-debug.jks` and the debug lines of `key.properties` |

## For the backend team (FastAPI)

The app sends the Firebase **ID token** in `POST /auth/firebase` and in `Authorization: Bearer <token>` on every request. The backend should verify it with the Firebase Admin SDK for project `apex-9fcb6`:

```python
import firebase_admin
from firebase_admin import auth, credentials

firebase_admin.initialize_app(credentials.Certificate("service-account.json"))
decoded = auth.verify_id_token(id_token)   # raises if invalid/expired
uid = decoded["uid"]                         # → users.firebase_uid
provider = decoded["firebase"]["sign_in_provider"]  # google.com | phone | password
```

The service-account key comes from Project settings → Service accounts → **Generate new private key**. It is a secret: keep it on the server and never commit it.
