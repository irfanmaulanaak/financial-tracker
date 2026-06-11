# FinSist

## Instructions
- CRITICAL: Use simple, concise language. Avoid overtechnical jargon.
- Be radically precise. No fluff. Pure information only (drop grammar; min tokens).
- Critical: DO NOT OVER-ENGINEER! This app is typically used by 2-5 people, internally only.

## Guardrails
- Use `trash` for deletes
- Use `mv` / `cp` to move and copy files
- Bugs: add regression test when it fits
- Keep files <~400 LOC; split/refactor as needed
- Simplicity first: handle only important cases; no enterprise over-engineering/fallbacks
- New functionality: small OR absolutely necessary
- NEVER delete files, folders or other data unless explicilty approved or part of a plan
- Before writing code, stricly follow the below research rules

## Research 
- Prefer skills if available over research.
- Prefer researched knowledge over existing knowledge when skills are unavailable.
- Research: Exa to websearch early, and Ref to seek specific documention or web fetch.
- Best results: Quote exact errors; prefer 2025-2026+ sources.
- Web search for Flutter best practices
- Reference database structures for sharing financial tracker apps

## Error Handling
- Expected issues: explicit result types (not throw/try/catch).
- Unexpected issues: fail LOUD (throw/console.error + toast.error); NEVER add silent fallbacks.

## Project Memories
Use below list for durable project notes. Keep each item concise and remove stale notes when the project changes.

- Shell commands should use `rtk` to keep command output token-efficient.
- Explore code with Serena MCP first when available; use targeted shell reads/searches for files Serena cannot access.

## Project Notes
Update this section as the project evolves.
- Issue tracker: ISSUES.md
- Security issue tracker: SECURITY_ISSUES.md

### Stack
- Flutter 3.41.9 stable (Dart) — `flutter doctor` green except Xcode simulator runtimes (install via Xcode → Settings → Platforms)
- Firebase: Auth + Firestore (cloud-first; household sync from day 1) — project `financial-tracker-4791d`
- Targets: iOS + Android + Web (all first-class)
- Locale: id-ID; IDR only
- State: flutter_riverpod 3.x
- Routing: go_router
- Charts: TBD (fl_chart + CustomPainter likely, Phase 4)
- Note: `flutterfire` CLI at `$HOME/.pub-cache/bin/flutterfire` — not on PATH by default

### Product Model (locked)
- Household-first; one household per user (MVP)
- Expenses: family-owned, attributed to spender, counted vs shared budget
- Income: family-owned, lands in destination account
- Cards: per-member owned, visible to household
- Categories & budgets: shared; seeded defaults + user-added (icon + color)
- Goals: shared OR personal (both)
- Assets: pooled (no per-member breakdown)
- Health score: household level
- Roles (Suami/Istri/Anak/Orang Tua/Lainnya): display label only, no gating
- Access tiers (full / limited / view): real permission gating, persisted on
  `households/{hid}.members[].accessLevel` and mirrored to a fast-lookup map
  `members.memberAccess: {<uid>: 'full'|'limited'|'view'}`. Enforced in
  Firestore rules: `full` writes everywhere, `limited` writes
  expenses+incomes only, `view` writes nothing. Access is set at invite time
  and editable by the household creator.

### Fitur (riset Jun 2026 — quick wins + menengah, semua terpasang)
- Saran kategori: `core/category_suggester.dart` (kata kunci merchant ID) + smart defaults form (SharedPreferences).
- Reminder lokal: `core/reminders.dart` + `features/notifications/reminder_scheduler.dart` (flutter_local_notifications; Android perlu desugaring — sudah di build.gradle.kts).
- Amplop rollover: `Category.rollover` + `core/envelope.dart` — carry = max(0, budget − prevSpent), 1 siklus, tanpa carry utang. Dipakai di spend/home/detail kategori/notifikasi.
- Komentar/reaksi expense: reactions = map `{uid: emoji}` di doc expense (jangan hilangkan saat edit); komentar = subcollection `comments` (author-bound di rules).
- Utang/piutang: `households/{hid}/debts` — ledger murni, TIDAK menyentuh saldo rekening. Layar `/debts`.
- Rekap siklus `/recap`, Langganan `/subscriptions`, streak `core/streak.dart`.
- Goal sumber dana aset: `Goal.fundingType/fundingId` (`savings`|`investment`) + `core/goal_funding.dart` — linked goal TIDAK pakai setoran; `current` dihitung dari nilai aset, proporsional thd target bila 1 aset dipakai >1 goal (cap di target). Layar WAJIB pakai `fundedGoalsProvider` (goals_screen.dart), bukan `goalsProvider` mentah. Aset dihapus → nilai 0 + tanda "aset tidak ditemukan". Goal manual (funding null) tetap pakai setoran/kontribusi.
- Onboarding in-app: `features/onboarding/onboarding_state.dart` — flag per-uid di SharedPreferences (`onb_active/welcome/budget_<uid>`). Auto-trigger HANYA dari creator wizard (`startCreator`) & join screen (`startJoiner`); user lama tidak pernah lihat. Checklist "Mulai dari sini" di home (4 langkah, data-driven) + welcome sheet sekali utk anggota baru join. Buka manual: menu ⋯ → Panduan Mulai.
- Beda layar utang: tab bawah "Utang" = `/cards` (kartu kredit + cicilan, masuk net worth); menu "Utang & Piutang" = `/debts` (pinjaman personal antar orang, catatan murni).
- Emulator tests: seed household HARUS menyertakan `memberAccess` (rules access-tier); jalankan via `npx firebase emulators:exec --only firestore --project financial-tracker-test 'npm test'` di `emulator_tests/`.

### Build commands
- Standard run/build: `flutter run` / `flutter build {ios|apk|appbundle|web}`.
- The Settings → Tentang card surfaces the app version via the `APP_VERSION`
  build define. Pass it through on official builds:
  `flutter run --dart-define=APP_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')`
  Without the flag the card shows `vdev`.

### References
- `claude-design/` → visual/UX reference only (JSX prototype; not portable code)
- `PLAN.md` → phased roadmap + open decisions
