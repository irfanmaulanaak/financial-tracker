# Project overview

Financial Tracker is a Flutter/Firebase household finance tracker for Indonesian families. It targets iOS and Android primarily, with web wired but optional. The product model is one household per user, shared household expenses/income/categories/budgets/cards/goals/investments, IDR only, locale id-ID.

Stack: Flutter 3.41.9 stable, Dart SDK ^3.11.5, Firebase Auth + Cloud Firestore, flutter_riverpod 3.x, go_router, intl, fl_chart, share_plus, path_provider, google_fonts. Firestore emulator tests live under emulator_tests and use @firebase/rules-unit-testing + mocha.

Key docs: AGENTS.md for repo guidance, PLAN.md for phase spec/current roadmap, SCHEMA.md for Firestore structure. claude-design/ is a JSX visual/UX reference only.