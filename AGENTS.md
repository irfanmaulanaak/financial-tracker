# OpenUsage

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

### Stack
- Flutter 3.41.9 stable (Dart) — `flutter doctor` green except Xcode simulator runtimes (install via Xcode → Settings → Platforms)
- Firebase: Auth + Firestore (cloud-first; household sync from day 1) — project `financial-tracker-4791d`
- Targets: iOS + Android primary; web also wired (optional)
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
- Roles (Istri/Suami/Anak): labels only, no permission gating

### References
- `claude-design/` → visual/UX reference only (JSX prototype; not portable code)
- `PLAN.md` → phased roadmap + open decisions
