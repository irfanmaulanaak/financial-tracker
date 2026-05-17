# Fix dummy data, dead UI & unconnected pieces

## Context

A code review of `refactor-design` flagged seven sites that ship hard-coded / mock data to the user and eight pieces of dead UI code left over from the Phase 1–5 refactor. The most visible offender is the home screen "Compact" (Layout B) sparkline, which is a synthetic upward curve unrelated to the user's finances. Other charts (goal detail bars, category detail daily bars) and a hard-coded allocation copy block share the same problem. Settings/Profile carry three dead `_noop`-wired rows each, and `About` shows a hard-coded `v1.0.0` string.

For the history-driven pieces we are going with **add persistence + real charts** rather than deleting them, so the plan introduces two new Firestore-backed series (net-worth snapshots and goal contributions) and wires the existing UI widgets to real data. The dead UI primitives are deleted outright.

---

## Phase 1 — Net-worth snapshots (home compact-layout sparkline)

**Goal:** real 14-point sparkline in `_DenseHero` and (optionally) the Editorial `AssetHeroCard` trend.

**Schema additions** (`SCHEMA.md` + `firestore.rules`):
```
households/{hid}/netWorthSnapshots/{YYYY-MM-DD}
  date: Timestamp                 // local midnight
  cash, savings, investments, debt, total: int (IDR)
  capturedBy: uid
```
Rules: read = any household member; write = signed-in member, restricted to today's doc id.

**New files:**
- `lib/src/features/home/net_worth_snapshot.dart` — immutable model + `fromMap` / `toMap`.
- `lib/src/features/home/net_worth_snapshot_repository.dart` — `recordToday({hid, NetWorth})` (idempotent: writes only if today's doc absent or its `total` differs), `recentSnapshots({hid, days})` stream.

**New provider** (lives next to repo): `netWorthHistoryProvider(int days)` returning `AsyncValue<List<NetWorthSnapshot>>` for the current household.

**Trigger:** in `home_screen.dart` (next to the existing `recurringRunnerProvider.run(...)` block, lines ~55-62), fire-and-forget `recordToday` after the first successful `nw` computation. Idempotent per day so repeated home builds are cheap.

**UI wiring:**
- `home_b_body.dart:_DenseHero` — accept a `List<double> trend` prop. Pass `FtSparkline(data: trend, color: …)` (replace local `Sparkline`).
- `home_screen.dart` — read `netWorthHistoryProvider(14)`, map to totals, pass into `HomeBBody` and `AssetHeroCard`. The Editorial layout's `AssetHeroCard` already accepts `trend` (`net_worth_section.dart:20`) — it currently receives nothing, so this lights up its existing branch (`net_worth_section.dart:86-92`).
- Delete the synthetic series at `home_b_body.dart:161-165`.

**Critical files:** `lib/src/features/home/home_screen.dart`, `lib/src/features/home/widgets/home_b_body.dart`, `lib/src/features/home/widgets/net_worth_section.dart`, `firestore.rules`, `SCHEMA.md`.

---

## Phase 2 — Goal contributions (goal detail "Setoran 8 Bulan Terakhir")

**Goal:** monthly bars driven by real contribution events. No more `goal.monthlyContrib * [0.8, 1.1, …]`.

**Schema additions:**
```
households/{hid}/goals/{goalId}/contributions/{contribId}
  amount: int
  at: Timestamp
  byUid: string
  source: 'manual' | 'autoDebit'
```
Rules: read = household member; write = household member; immutable after create.

**New file:** `lib/src/features/goals/contribution.dart` — model.

**Modify** `lib/src/features/goals/goal_repository.dart`:
- `contribute({hid, goalId, amount, byUid})` — wrap in transaction: increment `goal.current` + write contribution doc with `source: 'manual'`.

**Modify** `lib/src/features/goals/auto_debit_runner.dart` (lines 81-130 region) — when materializing the monthly debit, also write a contribution doc with `source: 'autoDebit'`.

**New provider:** `goalContributionsProvider({hid, goalId, monthsBack: 8})`.

**UI:** `lib/src/features/goals/goal_detail_screen.dart:75-85` — replace `contribs` list with a real `Map<YearMonth, int>` aggregation over the last 8 months. Empty months render as zero-height bars. Show a single-line "Belum ada riwayat setoran" caption when total = 0 (the chart card stays for layout continuity).

**Critical files:** `lib/src/features/goals/{goal_repository,auto_debit_runner,goal_detail_screen}.dart`, new `contribution.dart`, `firestore.rules`, `SCHEMA.md`.

---

## Phase 3 — Category detail real daily bars

No persistence needed — the data already exists.

**Modify** `lib/src/features/categories/category_detail_screen.dart:183-192`:
- Filter `cycleExpenses` by `categoryId == category.id`.
- Reuse `groupByDay()` from `lib/src/core/expense_aggregations.dart:45-52`.
- Build a 14-entry list keyed off `cycle.start..cycle.start+14d`; missing days → 0.
- Drop the `dailyAvg * (0.4 + (i/14) * 1.2)` synthesis.
- If `cycleExpenses` filtered list is empty, render the bar row at zero height (no breaking change to the chart card layout).

**Critical file:** `lib/src/features/categories/category_detail_screen.dart`.

---

## Phase 4 — Allocation "Profil Investasi" card

`AllocationRecommendation` already exposes a real `summary` string derived from the portfolio (`lib/src/core/allocation_recommendation.dart:48,162-164`), and `_AllocationCard` (`alokasi_tab.dart:200-211`) already renders it inside the same screen — the static "Profil moderat" `_ContextCard` is redundant.

**Modify** `lib/src/features/accounts/widgets/alokasi_tab.dart`:
- Remove the `_ContextCard` widget and its render in `_AlokasiTabState.build` (lines 71-72).
- Delete the `_ContextCard` class (lines 105-136).

**Critical file:** `lib/src/features/accounts/widgets/alokasi_tab.dart`.

---

## Phase 5 — Settings & Profile dead rows

**Settings** (`lib/src/features/settings/settings_screen.dart`):
- Convert `SettingsRow` (`lib/src/features/settings/widgets/settings_row.dart`) to accept `onTap: VoidCallback?` — when null, render without `FtTapScale` and without the trailing chevron (info-only style).
- "Mata uang · IDR · Rupiah" stays as info-only (no tap, no chevron).
- Delete the "Privasi & data" and "Bantuan & dukungan" rows.
- Delete the `_noop()` helper (`settings_screen.dart:124`).

**About card** (`settings_screen.dart:296-298`):
- Replace hard-coded `'v1.0.0 · …'` with `const String.fromEnvironment('APP_VERSION', defaultValue: 'dev')` interpolated into the string.
- Document the build flag (`--dart-define=APP_VERSION=1.0.0+1`) in `AGENTS.md` build commands section.

**Edit Profile** (`lib/src/features/profile/`):
- Remove the `SecurityCard()` render in `edit_profile_screen.dart:168`.
- Delete the `SecurityCard` and `_SecurityRow` classes in `lib/src/features/profile/widgets/edit_profile_parts.dart:264-359`.

**Critical files:** `lib/src/features/settings/{settings_screen.dart,widgets/settings_row.dart}`, `lib/src/features/profile/{edit_profile_screen.dart,widgets/edit_profile_parts.dart}`, `AGENTS.md`.

---

## Phase 6 — Dead UI code deletion

**Delete these files outright** (none have callers outside themselves; verified via grep across `lib/`):
- `lib/src/ui/ft_amount_display.dart`
- `lib/src/ui/ft_member_avatar.dart`
- `lib/src/ui/ft_member_chip.dart`
- `lib/src/ui/ft_glass_pill.dart`
- `lib/src/ui/ft_chip.dart`
- `lib/src/ui/ft_monthly_bars.dart`
- `lib/src/features/insights/spend_donut.dart`

**Delete the back-compat shims** in `lib/src/features/home/widgets/net_worth_section.dart:237-270` (`AssetHero`, `AssetBreakdown`).

**Delete the local `Sparkline`** in `lib/src/features/home/widgets/sparkline.dart` after Phase 1 migrates `_DenseHero` to `FtSparkline` (`lib/src/ui/ft_sparkline.dart`).

**Do not consolidate** `MiniDonut` (`lib/src/features/home/widgets/mini_donut.dart`) vs `FtDonut` yet — both are in active use; consolidation is out of scope.

---

## Verification

1. **Static:** `flutter analyze` — no new warnings.
2. **Unit tests:** add tests under `test/unit/`:
   - `net_worth_snapshot_repository_test.dart` — idempotent same-day write; ordering by date desc.
   - `goal_contribution_aggregation_test.dart` — month bucketing across year boundaries; empty-months produce zeros.
   - Extend `expense_aggregations_test.dart` if needed for the new daily-bar reducer (otherwise just compose `groupByDay` directly).
3. **Emulator rules tests** (`emulator_tests/rules/`):
   - `households/{hid}/netWorthSnapshots/{date}` — member read/write allowed, non-member denied, doc id pinned to today.
   - `households/{hid}/goals/{goalId}/contributions/{cid}` — household member create allowed, update/delete denied (immutable).
4. **Manual smoke (iOS sim or Android emu):**
   - Switch Settings → Tata Letak Beranda → Padat; first launch shows flat sparkline (1 snapshot), after a day of usage shows a real curve.
   - Record a goal contribution; bars in goal detail update on next read.
   - Add an expense to a category; category detail "Daily bars" reflects new value.
   - Allocation tab: only the dynamic summary card remains.
   - Settings: "Mata uang · IDR · Rupiah" non-tappable, no chevron; Privasi/Bantuan rows gone; About shows `v$APP_VERSION` from build flag.
   - Edit Profile: Security section gone.
5. **Run with version flag:** `flutter run --dart-define=APP_VERSION=$(cat pubspec.yaml | grep '^version:' | awk '{print $2}')` — verify About card text.

---

## Out of scope (note for follow-up)

- Backfilling historical net-worth snapshots (chart will only start populating from the first run post-deploy).
- Replacing the home-local `MiniDonut` with `FtDonut` everywhere.
- Wiring real Privacy / Help destinations.
