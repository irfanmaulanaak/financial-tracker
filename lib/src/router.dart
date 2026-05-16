import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/accounts/accounts_screen.dart';
import 'features/auth/email_link_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/cards/card_detail_screen.dart';
import 'features/cards/cards_screen.dart';
import 'features/categories/category_manage_screen.dart';
import 'features/expenses/expense_log_screen.dart';
import 'features/expenses/record_expense_screen.dart';
import 'features/export/export_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/home/home_screen.dart';
import 'features/household/household_providers.dart';
import 'features/incomes/income_log_screen.dart';
import 'features/incomes/record_income_screen.dart';
import 'features/insights/insights_screen.dart';
import 'features/investments/investments_screen.dart';
import 'features/members/member_list_screen.dart';
import 'features/onboarding/creator_wizard.dart';
import 'features/onboarding/join_household_screen.dart';
import 'features/onboarding/landing_screen.dart';
import 'core/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  final userDoc = ref.watch(currentUserDocProvider);
  final refresh = _ProviderRefreshNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final signedIn = auth.value != null;
      final loadingAuth = auth.isLoading;
      final hid = userDoc.value?['householdId'] as String?;
      final hasHousehold = hid != null && hid.isNotEmpty;
      final userDocLoading = signedIn && userDoc.isLoading;

      if (loadingAuth) return null;

      final authRoutes = {'/sign-in', '/sign-up', '/sign-in-link'};
      final onboardRoutes = {'/', '/onboard/create', '/onboard/join'};

      if (!signedIn) {
        return authRoutes.contains(loc) ? null : '/sign-in';
      }
      if (userDocLoading) return null;
      if (!hasHousehold) {
        return onboardRoutes.contains(loc) ? null : '/';
      }
      // Signed in + has household: keep them out of auth/onboarding screens.
      if (authRoutes.contains(loc) || onboardRoutes.contains(loc)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const LandingScreen()),
      GoRoute(path: '/sign-in', builder: (_, _) => const SignInScreen()),
      GoRoute(path: '/sign-up', builder: (_, _) => const SignUpScreen()),
      GoRoute(
          path: '/sign-in-link',
          builder: (_, _) => const EmailLinkScreen()),
      GoRoute(
        path: '/onboard/create',
        builder: (_, _) => const CreatorWizardScreen(),
      ),
      GoRoute(
        path: '/onboard/join',
        builder: (_, _) => const JoinHouseholdScreen(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/expenses',
        builder: (_, _) => const ExpenseLogScreen(),
      ),
      GoRoute(
        path: '/expenses/new',
        builder: (_, _) => const RecordExpenseScreen(),
      ),
      GoRoute(
        path: '/categories',
        builder: (_, _) => const CategoryManageScreen(),
      ),
      GoRoute(
        path: '/members',
        builder: (_, _) => const MemberListScreen(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (_, _) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/incomes',
        builder: (_, _) => const IncomeLogScreen(),
      ),
      GoRoute(
        path: '/incomes/new',
        builder: (_, _) => const RecordIncomeScreen(),
      ),
      GoRoute(
        path: '/cards',
        builder: (_, _) => const CardsScreen(),
      ),
      GoRoute(
        path: '/cards/:cardId',
        builder: (_, state) =>
            CardDetailScreen(cardId: state.pathParameters['cardId']!),
      ),
      GoRoute(path: '/insights', builder: (_, _) => const InsightsScreen()),
      GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
      GoRoute(
          path: '/investments',
          builder: (_, _) => const InvestmentsScreen()),
      GoRoute(path: '/export', builder: (_, _) => const ExportScreen()),
    ],
  );
});

/// Bridges a Riverpod provider rebuild into go_router's refresh.
class _ProviderRefreshNotifier extends ChangeNotifier {
  _ProviderRefreshNotifier(this._ref) {
    _subs.add(_ref.listen(authStateProvider, (_, _) => notifyListeners()));
    _subs.add(
        _ref.listen(currentUserDocProvider, (_, _) => notifyListeners()));
  }
  final Ref _ref;
  final List<ProviderSubscription> _subs = [];

  @override
  void dispose() {
    for (final s in _subs) {
      s.close();
    }
    super.dispose();
  }
}
