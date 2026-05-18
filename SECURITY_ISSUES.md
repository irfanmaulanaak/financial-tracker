# Security Issues

Keep only active security issues here. Remove an issue once it is fully addressed.

Review baseline:
- OWASP Web Top 10: broken access control, security misconfiguration, auth failures.
- OWASP Mobile Top 10 2024: credential misuse, insecure authz, insecure storage, insecure communication.
- Firebase guidance: deny by default, treat security rules as schema, unit-test rules, enable App Check, restrict abuse.

## Active

_None — SEC-001..SEC-008 closed by the `fix_security_issues_8d893703` plan. Re-open here when new findings land._

## Manual rollout follow-ups (not code)

- **App Check enforcement:** flip Firestore App Check enforcement ON in the Firebase console once all clients (web + Android + iOS) ship with the App Check provider.
- **Android upload keystore:** generate the production upload keystore once, then load `ANDROID_KEYSTORE_BASE64` (base64-encoded `.jks`) and `ANDROID_KEY_PROPS` (contents of `android/key.properties`) into the GH Actions secrets store. The CI build job is wired to consume both.
- **reCAPTCHA v3 site key:** add `RECAPTCHA_V3_SITE_KEY` to the GH Actions secrets store so the web build forwards it to `firebase_app_check` via `--dart-define=FT_RECAPTCHA_V3_SITE_KEY=...`.
