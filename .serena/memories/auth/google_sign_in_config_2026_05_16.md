# Google Sign-In config note

User hit the friendly error `Konfigurasi Google Sign-In belum lengkap`. Diagnosis was `android/app/google-services.json` had an empty `oauth_client` array, so native Android Google Sign-In had no web OAuth client (`client_type: 3`) for `google_sign_in` v7.

Resolved on 2026-05-16: user reran FlutterFire configuration. `android/app/google-services.json` now contains a web OAuth client with `client_type: 3` (`361266947064-v28oc1mqmucehibejqqq1vngp3nk5g0k.apps.googleusercontent.com`) and iOS still has `CLIENT_ID` / `REVERSED_CLIENT_ID` in `ios/Runner/GoogleService-Info.plist`.

Code state: web uses Firebase Auth `signInWithPopup(GoogleAuthProvider())` instead of `google_sign_in`, and native platforms initialize `GoogleSignIn` only off web. The Android config issue was removed from `ISSUES.md` after verification.