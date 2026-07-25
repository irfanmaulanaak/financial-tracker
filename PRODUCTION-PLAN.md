# FinSist — Production Release Plan (draft 2026-07-25)

Status: PLANNING ONLY — owner has frozen code changes. Nothing here is dispatched.
Sources: full repo audit (file:line evidence) + 2026 store-requirement research.
Verdict from audit: NOT releasable today. Two hard blockers + legal/observability gaps.
The good news: firestore.rules is genuinely strong, manifest hygiene is textbook,
git history is clean of secrets, and 313 tests + 10 emulator rules-test files exist.

## Phase 0 — Owner-only actions (no agent can do these)
- [ ] O1. ROTATE the reCAPTCHA v3 secret key now — a live server secret sits in `.env:2`
      (never committed, but plaintext on disk). Rotate in console, then delete the file
      or move to a secret manager. 5 minutes, do it first.
- [ ] O2. Google Play Console account ($25) + Apple Developer Program ($99/yr) if not owned.
- [ ] O3. Decide privacy-policy hosting (needs a public URL, not PDF; GitHub Pages works)
      and a web page for account deletion requests (Play requires an external route too).
- [ ] O4. Real keystore passwords: `android/key.properties` currently has placeholder
      `password` values and points at a path that doesn't exist. Confirm where the real
      credentials for `finsist-upload-keystore.jks` live.
- [ ] O5. Store listing assets: screenshots (fresh after the design work), 512×512 icon,
      1024×500 feature graphic, Indonesian listing copy.

## Phase 1 — Release blockers (heavy → codex)
- [ ] C1. Wire release signing: load `key.properties` in `android/app/build.gradle.kts`,
      create `signingConfigs.release`, replace the debug signingConfig (line 42, TODO at 40),
      move/point keystore path correctly. Add `flutter build appbundle` with
      `--obfuscate --split-debug-info` to CI (the ".gitignore SEC-007 step" that was
      documented but never written), R8 keep rules for plugins.
- [ ] C2. Crash reporting + error handlers: add firebase_crashlytics; in main.dart wire
      FlutterError.onError, PlatformDispatcher.instance.onError, runZonedGuarded;
      symbol upload step in CI. A finance app cannot ship blind.
- [ ] C3. Compliant account deletion: delete `users/{uid}` doc + household membership
      cleanup on account deletion (currently orphans all Firestore data — dialog even
      admits it); handle `requires-recent-login` with reauthentication (doc comment
      promises it, code doesn't do it); add the external web deletion route (O3).
- [ ] C4. Firestore hardening for public deployment: close ISSUES.md §3 (household root
      `get` open to any signed-in user — the "internal app" rationale expires at release);
      add Firebase App Check; run the 10 emulator rules tests in CI (needs the missing
      emulator_tests/package-lock.json committed first).
- [ ] C5. iOS submission surface: app-level PrivacyInfo.xcprivacy; add Sign in with Apple
      (Guideline 4.8 — Google Sign-In alone gets rejected); ITSAppUsesNonExemptEncryption
      key; iOS build job in CI.

## Phase 2 — Light tasks (→ opencode)
- [ ] L1. Android backup policy: explicit `dataExtractionRules`/`fullBackupContent`
      excluding shared_preferences (finance data must not silently ride device backup).
- [ ] L2. Version hygiene: bump pubspec to a real `1.0.0+N`; feed APP_VERSION dart-define
      to Android/iOS builds (settings screen currently shows "dev" on mobile).
- [ ] L3. In-app privacy-policy + ToS links in settings (URL from O3).
- [ ] L4. Fix CFBundleName (`financial_tracker` → FinSist) and confirm bundle-id records
      match store entries before first upload (IDs are permanent after that).
- [ ] L5. Email-link sign-in: configure Universal/App Links or hide that method for v1
      (current flow requires pasting the link back — a reviewer-facing failure).
- [ ] L6. Lint hardening: enable avoid_print + analyzer errors escalation.

## Phase 3 — Store submission mechanics (owner + Claude together)
- [ ] S1. Play Data safety form: Financial info + Personal info collected; encrypted in
      transit; deletion mechanism = C3; matches privacy policy. Firebase SDK disclosure
      tables referenced in research.
- [ ] S2. Play: internal testing track first, pre-launch report, then production.
- [ ] S3. iOS: Privacy Nutrition Labels matching the manifest; TestFlight; review notes
      with a demo account (reviewers must be able to sign in).
- [ ] S4. Post-launch runbook: crash-free-rate monitoring, hotfix branch, target-SDK
      deadline calendar.

## Suggested order
O1 immediately → Phase 1 C1+C2 (unblock signed observable builds) → C3+C4 (policy/
security) → Phase 2 in parallel → C5 (iOS can trail Android) → Phase 3.
Realistic scope: Phases 1-2 are roughly 2-4 agent-days of work; Phase 3 is mostly
console forms and waiting on review queues.
