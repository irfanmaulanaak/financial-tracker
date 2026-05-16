# Code structure

lib/main.dart initializes Firebase and ProviderScope. lib/src/app.dart builds MaterialApp.router with id-ID localization and buildTheme(). lib/src/router.dart defines auth/onboarding/home routing.

lib/src/core contains pure helpers: payday cycles, formatters, aggregations, net worth, cicilan, health score, category analysis, recurring helper, CSV export, in-app indicators, seeded data, ids/providers.

lib/src/features contains feature modules: auth, onboarding, household, members, categories, expenses, incomes, accounts, cards, home, insights, goals, investments, export. Repositories wrap Firestore writes/transactions. Screens are Flutter widgets using Riverpod and go_router.

test/unit contains pure Dart tests. emulator_tests/rules contains Firestore emulator integration/rules tests. claude-design contains JSX prototype files for visual reference.