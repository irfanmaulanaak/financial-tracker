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
- Utang kartu = 2 angka (Jun 2026): `used` = tampilan ala app BCA (cicilan tertagih belum dibayar; pre-block penuh sebelum tagihan pertama; lompat di `billingDay` — by design) untuk UI kartu/limit. `outstanding` = utang riil (SELURUH sisa cicilan + transaksi belum dibayar; bebas tanggal) — dipakai net worth + health score. `plainPaid` di doc kartu = akumulasi pembayaran transaksi reguler (cicilan via `monthsPaid`). Semua dihitung `cardDebtTotals()` di `core/cicilan.dart`, ditulis `recalcUsed`. Regression: `test/unit/cicilan_test.dart` group `cardDebtTotals`.
- Tagihan bulanan kartu (Jul 2026): transaksi "Lunas" (non-cicilan) juga ikut siklus tutup tagihan — `billedPlainDue()` di `core/cicilan.dart` (belanja setelah tanggal tutup = masuk tagihan bulan DEPAN, tapi tetap makan limit `used` seketika, sama seperti bank). Dipakai `payMonthlyBill` + `PayCardSheet` (sheet tampilkan note "belum tertagih"). `used` di kalender/reminder = sisa kartu (aproksimasi, bukan angka statement). Regression: group `billedPlainDue`.

### Fitur ronde 2 (riset Jun 2026 — semua terpasang)
- Kunci app: `core/app_lock.dart` + `features/security/` — default OFF, toggle di Settings → Akun & Keamanan. PIN di-hash SHA-256+salt di `flutter_secure_storage`; biometrik via `local_auth` (Android perlu `FlutterFragmentActivity` + izin USE_BIOMETRIC; iOS NSFaceIDUsageDescription). Gate di `app.dart` (`AppLockGate`), kunci saat app paused.
- Streak pemaaf: `recordingStreak(grace: 1)` — 1 hari bolong tidak putus (tidak menambah hitungan).
- Favorit expense: `favorite_expenses.dart` (SharedPreferences, cap 6) + chip di form catat; "Simpan & tambah lagi" reset form tapi pertahankan tanggal+metode.
- Geser anggaran: `core/budget_move.dart` + `Household.budgetMoves` (cap 30, jejak by/at) + `BudgetMoveSheet`; entry dari banner over-budget detail kategori, Money Date, recap.
- Milestone goal 50%/100%: `goalMilestoneCrossed` di `goal.dart` → FtCelebrate di goal detail.
- Notifikasi: rekap mingguan (Minggu 18:00) + money date (2 hari sebelum gajian 19:30) — `core/reminder_times.dart`, toggle di Settings.
- Money Date `/money-date`: 4 langkah (rayakan → sorotan → tagihan 7 hari → 1 keputusan), data delta dari `core/money_date.dart`.
- Minta-cek transaksi: `Expense.review` map `{by,to,done,at}` (JANGAN hilangkan saat edit — sudah di-carry di repo), tombol di detail sheet, badge "minta dicek" di daftar. Repo: `ExpenseSocialRepository.requestReview/resolveReview/clearReview`.
- Kalender tagihan `/calendar` (menu ⋯): jatuh tempo kartu + tagihan rutin s/d akhir siklus (`core/upcoming.dart`) + proyeksi sisa kas (`core/cash_projection.dart` — kas − tagihan − rata² harian × sisa hari).
- Split transaksi: `core/split_expense.dart` + `SplitExpenseSheet` — N pengeluaran biasa per bagian (tanpa perubahan model), tombol di form catat saat amount > 0.
- ZISWAF: `Category.ziswaf` (toggle di kelola kategori) → kartu total siklus + total tahun berjalan di `/recap` (`ziswafYearExpensesProvider`).
- Insight harian: `core/daily_insight.dart` (aturan berprioritas, pure) + `DailyInsightLine` di home — maks 1 kalimat/hari, dikunci via SharedPreferences (`insight_day/text`).
- Hero "aman dibelanjakan": slide pertama carousel home — `core/safe_to_spend.dart` (sisa budget+carry ÷ hari tersisa) dengan anotasi cara hitung.
- Tema Liquid Glass (beta, Jun 2026): toggle Settings → Tampilan (`liquidThemeProvider`, pref `liquid_theme`). `FtColors.liquid` statis (pola sama brightness, flip → `ftRebuildAllWidgets`). Saat ON: scaffold transparan + `FtLiquidBackground` global di `app.dart` (6 blob drift loop 20s), chrome pakai `ui/ft_glass.dart` + `ui/ft_glass_fx.dart` (blur+saturasi+lensa wallpaper+rim specular+sweep+touch glow; fallback solid = tampilan klasik persis; high-contrast & reduce-motion dihormati). Glass penuh (blur backdrop) HANYA chrome (bottom/side nav, action sheet — scrim modal menipis 0.18); `FtCard` pakai `FtGlass(lite:true)` — lensa 1 proyeksi + tint pekat 0.50–0.58; kartu ber-`backgroundColor` eksplisit tetap solid. Animasi liquid: pill nav easeOutBack, FtTapScale squash-stretch elasticOut. Lab debug: `/dev/liquid` (bypass auth kDebugMode + tombol "Lab" di sign-in). Regression: `test/widget/ft_glass_test.dart`.
- Perf Liquid (Jul 2026, jangan diregres): scene dirender SEKALI per langkah (~12 fps, `Timer` — BUKAN Ticker: ticker menjadwalkan frame tiap vsync dan web/canvaskit re-raster semua) ke `ui.Image` bersama (`LiquidFrame`, resolusi dibudget ±0.35 MP); background + semua lensa cuma `drawImageRect` (tanpa saveLayer — alpha via paint). Painter WAJIB baca `frame.image` di paint() (bukan capture saat build; image lama di-dispose tiap langkah). Touch glow HANYA chrome (Listener per kartu = repaint per pointer-move saat drag = jank scroll). Sweep pakai Timer idle (5.4s diam, 1.6s sapu). Timer stop saat app paused / reduce-motion / liquid OFF. Profil Chrome lab idle: 529 → ~200 busy-sample/dtk (floor OFF = 5). PENTING: `routerProvider` JANGAN `ref.watch` auth/userDoc di body (GoRouter dibuat ulang tiap emit → navigasi terlempar ke '/'); pakai `ref.read` dalam redirect + `refreshListenable` (sudah diperbaiki Jun 2026). Toggle tema: `themeAnimationDuration: Duration.zero` di app.dart WAJIB — crossfade AnimatedTheme bikin `Theme.of` di frame pertama masih brightness lama padahal `ftRebuildAllWidgets` jalan di frame itu → UI basi sampai "refresh". Statics di-sync dari resolusi themeMode (bukan Theme.of) + post-frame rebuild bila brightness berubah tanpa toggle (mode system).
- Banner home (`AlertBand`) sekarang punya aksi opsional (`actionLabel`/`onAction`) — peringatan selalu berpasangan langkah berikutnya; copy non-blaming.

### Build commands
- Standard run/build: `flutter run` / `flutter build {ios|apk|appbundle|web}`.
- The Settings → Tentang card surfaces the app version via the `APP_VERSION`
  build define. Pass it through on official builds:
  `flutter run --dart-define=APP_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')`
  Without the flag the card shows `vdev`.

### References
- `claude-design/` → visual/UX reference only (JSX prototype; not portable code)
- `PLAN.md` → phased roadmap + open decisions
