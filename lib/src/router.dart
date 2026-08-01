import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/accounts/account_detail_screen.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/auth/email_link_screen.dart';
import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/cards/card_detail_screen.dart';
import 'features/cards/cards_screen.dart';
import 'features/categories/category_detail_screen.dart';
import 'features/categories/category_manage_screen.dart';
import 'features/debts/debts_screen.dart';
import 'features/dev/liquid_preview_screen.dart';
import 'features/expenses/edit_expense_screen.dart';
import 'features/expenses/expense_log_screen.dart';
import 'features/expenses/record_expense_screen.dart';
import 'features/export/export_screen.dart';
import 'features/goals/add_goal_screen.dart';
import 'features/goals/goal_detail_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/health/health_screen.dart';
import 'features/home/home_screen.dart';
import 'features/household/household_providers.dart';
import 'features/incomes/income_log_screen.dart';
import 'features/incomes/record_income_screen.dart';
import 'features/insights/bill_calendar_screen.dart';
import 'features/insights/money_date_screen.dart';
import 'features/insights/recap_screen.dart';
import 'features/members/member_detail_screen.dart';
import 'features/members/member_list_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/obligations/obligations_screen.dart';
import 'features/onboarding/creator_wizard.dart';
import 'features/onboarding/join_household_screen.dart';
import 'features/onboarding/landing_screen.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/recurring/subscriptions_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/spend/spend_screen.dart';
import 'features/transfers/transfer_screen.dart';
import 'ui/ft_motion.dart';
import 'core/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _ProviderRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      // PENTING: baca via ref.read, BUKAN ref.watch di body provider —
      // watch membuat GoRouter dibangun ulang tiap stream emit (auth token,
      // perubahan user doc) dan navigasi mental balik ke '/'.
      // refreshListenable di atas yang memicu evaluasi ulang redirect.
      final auth = ref.read(authStateProvider);
      final userDoc = ref.read(currentUserDocProvider);
      final loc = state.matchedLocation;
      // Lab tampilan liquid — debug only, lewati seluruh guard auth.
      if (kDebugMode &&
          (loc == '/dev/liquid' || state.uri.path == '/dev/liquid')) {
        return null;
      }
      final signedIn = auth.value != null;
      final loadingAuth = auth.isLoading;
      final hid = userDoc.value?['householdId'] as String?;
      final hasHousehold = hid != null && hid.isNotEmpty;
      final userDocLoading = signedIn && userDoc.isLoading;

      // `/` renders the in-app splash. While auth or user-doc is still
      // loading we keep the user there so they never see a flash of
      // landing/home before state resolves.
      if (loadingAuth) return loc == '/' ? null : '/';

      final authRoutes = {'/sign-in', '/sign-up', '/sign-in-link'};
      final onboardRoutes = {'/landing', '/onboard/create', '/onboard/join'};

      if (!signedIn) {
        return authRoutes.contains(loc) ? null : '/sign-in';
      }
      if (userDocLoading) return loc == '/' ? null : '/';
      if (!hasHousehold) {
        return onboardRoutes.contains(loc) ? null : '/landing';
      }
      // Signed in + has household: keep them out of splash / auth / onboarding.
      if (loc == '/' ||
          authRoutes.contains(loc) ||
          onboardRoutes.contains(loc)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/landing', builder: (_, _) => const LandingScreen()),
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
      _fadeRoute('/spend', (_) => const SpendScreen()),
      _fadeRoute('/expenses', (_) => const ExpenseLogScreen()),
      _bottomSlideRoute('/expenses/new', (_) => const RecordExpenseScreen()),
      _scaleRoute('/expenses/:expenseId/edit', (state) =>
          EditExpenseScreen(expenseId: state.pathParameters['expenseId']!)),
      _fadeRoute('/categories', (_) => const CategoryManageScreen()),
      _scaleRoute('/categories/:categoryId', (state) =>
          CategoryDetailScreen(categoryId: state.pathParameters['categoryId']!)),
      _fadeRoute('/members', (_) => const MemberListScreen()),
      _scaleRoute('/members/:memberId', (state) =>
          MemberDetailScreen(memberId: state.pathParameters['memberId']!)),
      _fadeRoute('/notifications', (_) => const NotificationsScreen()),
      _fadeRoute('/profile/edit', (_) => const EditProfileScreen()),
      _fadeRoute('/accounts', (_) => const AccountsScreen()),
      _scaleRoute('/accounts/:accountId', (state) =>
          AccountDetailScreen(accountId: state.pathParameters['accountId']!)),
      _fadeRoute('/incomes', (_) => const IncomeLogScreen()),
      _bottomSlideRoute('/incomes/new', (_) => const RecordIncomeScreen()),
      _bottomSlideRoute('/transfer/new', (_) => const TransferScreen()),
      _fadeRoute('/cards', (_) => const CardsScreen()),
      _scaleRoute('/cards/:cardId', (state) =>
          CardDetailScreen(cardId: state.pathParameters['cardId']!)),
      _fadeRoute('/health', (_) => const HealthScreen()),
      _fadeRoute('/recap', (_) => const RecapScreen()),
      _bottomSlideRoute('/money-date', (_) => const MoneyDateScreen()),
      _fadeRoute('/goals', (_) => const GoalsScreen()),
      _bottomSlideRoute('/goals/new', (_) => const AddGoalScreen()),
      _scaleRoute('/goals/:goalId', (state) =>
          GoalDetailScreen(goalId: state.pathParameters['goalId']!)),
      _fadeRoute('/export', (_) => const ExportScreen()),
      _fadeRoute('/subscriptions', (_) => const SubscriptionsScreen()),
      _fadeRoute('/calendar', (_) => const BillCalendarScreen()),
      _fadeRoute('/debts', (_) => const DebtsScreen()),
      _fadeRoute('/obligations', (_) => const ObligationsScreen()),
      _fadeRoute('/settings', (_) => const SettingsScreen()),
      if (kDebugMode)
        _fadeRoute('/dev/liquid', (_) => const LiquidPreviewScreen()),
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

GoRoute _scaleRoute(String path, Widget Function(GoRouterState) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => ftScaleUpPage(context, state,
        child: builder(state)),
  );
}

GoRoute _bottomSlideRoute(
    String path, Widget Function(GoRouterState) builder) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) => ftBottomSlidePage(context, state,
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
