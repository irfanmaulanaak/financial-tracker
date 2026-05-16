import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/accounts/accounts_screen.dart';
import 'features/auth/email_link_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/cards/card_detail_screen.dart';
import 'features/cards/cards_screen.dart';
import 'features/categories/category_detail_screen.dart';
import 'features/categories/category_manage_screen.dart';
import 'features/expenses/expense_log_screen.dart';
import 'features/expenses/record_expense_screen.dart';
import 'features/export/export_screen.dart';
import 'features/goals/goal_detail_screen.dart';
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
import 'features/settings/settings_screen.dart';
import 'ui/ft_motion.dart';
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
      _fadeRoute('/home', (_) => const HomeScreen()),
      _fadeRoute('/expenses', (_) => const ExpenseLogScreen()),
      _fadeRoute('/expenses/new', (_) => const RecordExpenseScreen()),
      _fadeRoute('/categories', (_) => const CategoryManageScreen()),
      _fadeRoute('/categories/:categoryId', (state) =>
          CategoryDetailScreen(categoryId: state.pathParameters['categoryId']!)),
      _fadeRoute('/members', (_) => const MemberListScreen()),
      _fadeRoute('/accounts', (_) => const AccountsScreen()),
      _fadeRoute('/incomes', (_) => const IncomeLogScreen()),
      _fadeRoute('/incomes/new', (_) => const RecordIncomeScreen()),
      _fadeRoute('/cards', (_) => const CardsScreen()),
      _fadeRoute('/cards/:cardId', (state) =>
          CardDetailScreen(cardId: state.pathParameters['cardId']!)),
      _fadeRoute('/insights', (_) => const InsightsScreen()),
      _fadeRoute('/goals', (_) => const GoalsScreen()),
      _fadeRoute('/goals/:goalId', (state) =>
          GoalDetailScreen(goalId: state.pathParameters['goalId']!)),
      _fadeRoute('/investments', (_) => const InvestmentsScreen()),
      _fadeRoute('/export', (_) => const ExportScreen()),
      _fadeRoute('/settings', (_) => const SettingsScreen()),
    ],
  );
});

GoRoute _fadeRoute(String path, Widget Function(GoRouterState) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => ftFadeUpPage(context, state,
        child: builder(state)),
  );
}

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
