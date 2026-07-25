import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../core/theme_provider.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../auth/auth_repository.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';
import '../members/invite_sheet.dart';
import 'widgets/household_section.dart';
import 'widgets/members_section.dart';
import 'widgets/reminders_section.dart';
import 'widgets/security_section.dart';
import 'widgets/settings_row.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final canFull = ref.watch(canWriteAllProvider);

    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.home,
        child: FtRefreshable(
          onRefresh: () async {
            ref.invalidate(currentHouseholdProvider);
            await ftRefreshDelay();
          },
          child: ListView(
          padding: const EdgeInsets.only(bottom: kFtFabClearance),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const FtSubHeader(title: 'Profil'),
            _ProfileCard(
              user: user,
              household: household,
              onEdit: () => context.push('/profile/edit'),
            ),
            MembersSection(
              household: household,
              currentUid: user.uid,
              onInvite: () {
                if (!canFull) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tidak punya akses untuk tindakan ini.'),
                    ),
                  );
                  return;
                }
                InviteMemberSheet.show(
                  context,
                  householdId: household.id,
                  householdName: household.name,
                  creatorUid: user.uid,
                );
              },
            ),
            _DisplaySection(themeMode: themeMode, ref: ref),
            const RemindersSection(),
            HouseholdSection(
              household: household,
              canEdit: canFull,
              ref: ref,
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Eyebrow('Akun & Keamanan'),
            ),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              padding: EdgeInsets.zero,
              child: Column(
                children: const [
                  SettingsRow(
                    label: 'Mata uang',
                    detail: 'IDR · Rupiah',
                  ),
                  AppLockRows(),
                ],
              ),
            ),
            const _AboutCard(),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: OutlinedButton(
                onPressed: () async {
                  FtHaptics.warning();
                  try {
                    await ref.read(authRepositoryProvider).signOut();
                  } catch (e) {
                    if (context.mounted) {
                      showFtErrorSnack(context, e, prefix: 'Gagal keluar');
                    }
                  }
                },
                child: const Text('Keluar'),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.household,
    required this.onEdit,
  });
  final User user;
  final Household household;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final displayName = prettyName(user.displayName ?? user.email ?? 'User');
    return FtTapScale(
      scale: 0.99,
      onTap: onEdit,
      child: FtCard(
        margin: const EdgeInsets.fromLTRB(22, 4, 22, 18),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: FtColors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: FtColors.lineStrong, width: 0.5),
              ),
              alignment: Alignment.center,
              child: Text(
                initialsOf(user.displayName ?? user.email ?? 'User'),
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 22,
                  color: FtColors.ink,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Bergabung ${Dates.short(household.createdAt)}',
                    style: TextStyle(color: FtColors.ink3, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: FtColors.ink4),
          ],
        ),
      ),
    );
  }
}

class _DisplaySection extends ConsumerWidget {
  const _DisplaySection({
    required this.themeMode,
    required this.ref,
  });
  final ThemeMode themeMode;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final liquid = ref.watch(liquidThemeProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
          child: Eyebrow('Tampilan'),
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              SettingsToggleRow(
                label: 'Tema',
                value: themeMode == ThemeMode.dark ? 'Gelap' : 'Terang',
                child: Row(
                  children: [
                    SettingsChoiceChip(
                      label: 'Terang',
                      active: themeMode != ThemeMode.dark,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.light),
                    ),
                    const SizedBox(width: 8),
                    SettingsChoiceChip(
                      label: 'Gelap',
                      active: themeMode == ThemeMode.dark,
                      onTap: () => ref
                          .read(themeModeProvider.notifier)
                          .setTheme(ThemeMode.dark),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SettingsSwitchRow(
                label: 'Liquid Glass',
                detail: 'Tampilan kaca + background hidup (eksperimen)',
                value: liquid,
                trailing: const _BetaBadge(),
                onChanged: (v) =>
                    ref.read(liquidThemeProvider.notifier).setLiquid(v),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BetaBadge extends StatelessWidget {
  const _BetaBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: FtColors.clay.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: FtColors.clay.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Text(
        'BETA',
        style: TextStyle(
          fontSize: 9,
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
          color: FtColors.clay,
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  // Set at build time via `--dart-define=APP_VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')`.
  static const _appVersion =
      String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
          child: Eyebrow('Tentang'),
        ),
        FtCard(
          margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FinSist',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'v$_appVersion · Dibuat untuk keluarga Indonesia.\nData disimpan di perangkat & cloud (Firebase).',
                style: TextStyle(
                    color: FtColors.ink3, fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
