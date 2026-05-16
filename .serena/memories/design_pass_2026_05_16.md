# Design pass 2026-05-16

The user asked to prioritize fixing mismatches with `claude-design/` and to track active issues in `ISSUES.md`.

Implemented design alignment across active Flutter product surfaces: home, accounts/assets, cards, card detail, goals, insights, expense/income logs, record expense/income, investments, export, members, categories, and onboarding create/join/landing screens. The UI now uses the shared warm editorial FT primitives in `lib/src/ui/ft_ui.dart` (`FtCard`, `FtSubHeader`, `FtAppChrome`, etc.) and removes stock `AppBar`/`FloatingActionButton` usage from `lib/src/features`.

`ISSUES.md` should keep only active issues. The design mismatch issue was removed after this pass. A new active issue remains for oversized UI files caused by the design work: `home_screen.dart`, `goals_screen.dart`, and `accounts_screen.dart` should be split later to satisfy the project guardrail.