import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/home_layout_provider.dart';
import '../../core/theme_provider.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_motion.dart';
import '../../ui/ft_ui.dart';
import '../auth/auth_repository.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/name_format.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    final themeMode = ref.watch(themeModeProvider);
    final layout = ref.watch(homeLayoutProvider);

    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtAppChrome(
        current: FtTab.home,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const FtSubHeader(title: 'Profil'),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 4, 22, 18),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: FtColors.surfaceAlt,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: FtColors.lineStrong, width: 0.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initialsOf(
                          user.displayName ?? user.email ?? 'User'),
                      style: const TextStyle(
                        fontFamily: 'Newsreader',
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
                          prettyName(
                              user.displayName ?? user.email ?? 'User'),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bergabung ${Dates.short(household.createdAt)}',
                          style: const TextStyle(
                              color: FtColors.ink3, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _MembersSection(household: household),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Eyebrow('Tampilan'),
            ),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ToggleRow(
                    label: 'Tema',
                    value: themeMode == ThemeMode.dark ? 'Gelap' : 'Terang',
                    child: Row(
                      children: [
                        _ChoiceChip(
                          label: 'Terang',
                          active: themeMode != ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setTheme(ThemeMode.light),
                        ),
                        const SizedBox(width: 8),
                        _ChoiceChip(
                          label: 'Gelap',
                          active: themeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setTheme(ThemeMode.dark),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  _ToggleRow(
                    label: 'Tata Letak Beranda',
                    value: layout == 'B' ? 'Padat' : 'Editorial',
                    child: Row(
                      children: [
                        _ChoiceChip(
                          label: 'Editorial',
                          active: layout == 'A',
                          onTap: () => ref
                              .read(homeLayoutProvider.notifier)
                              .setLayout('A'),
                        ),
                        const SizedBox(width: 8),
                        _ChoiceChip(
                          label: 'Padat',
                          active: layout == 'B',
                          onTap: () => ref
                              .read(homeLayoutProvider.notifier)
                              .setLayout('B'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Eyebrow('Rumah Tangga'),
            ),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    label: 'Nama keluarga',
                    detail: household.name,
                    onTap: () => _editHouseholdName(context, ref, household),
                  ),
                  const Divider(),
                  _SettingsRow(
                    label: 'Tanggal gajian',
                    detail: 'Tgl ${household.payday}',
                    onTap: () => _editPayday(context, ref, household),
                  ),
                  const Divider(),
                  _SettingsRow(
                    label: 'Anggaran bulanan',
                    detail: Money.format(household.monthlyBudgetTotal),
                    onTap: () => _editBudget(context, ref, household),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Eyebrow('Akun & Keamanan'),
            ),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsRow(
                    label: 'Mata uang',
                    detail: 'IDR · Rupiah',
                    onTap: () {},
                  ),
                  const Divider(),
                  _SettingsRow(
                    label: 'Privasi & data',
                    detail: '',
                    onTap: () {},
                  ),
                  const Divider(),
                  _SettingsRow(
                    label: 'Bantuan & dukungan',
                    detail: '',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 18, 22, 8),
              child: Eyebrow('Tentang'),
            ),
            FtCard(
              margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Financial Tracker',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'v1.0.0 · Dibuat untuk keluarga Indonesia.\nData disimpan di perangkat & cloud (Firebase).',
                    style: TextStyle(
                        color: FtColors.ink3, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: OutlinedButton(
                onPressed: () {
                  FtHaptics.warning();
                  ref.read(authRepositoryProvider).signOut();
                },
                child: const Text('Keluar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editHouseholdName(
    BuildContext context,
    WidgetRef ref,
    Household household,
  ) async {
    final ctrl = TextEditingController(text: household.name);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nama keluarga'),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'Mis. Keluarga Andini'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true && ctrl.text.trim().isNotEmpty) {
      await ref
          .read(firestoreProvider)
          .collection('households')
          .doc(household.id)
          .update({'name': ctrl.text.trim()});
    }
    ctrl.dispose();
  }

  Future<void> _editPayday(
    BuildContext context,
    WidgetRef ref,
    Household household,
  ) async {
    int selected = household.payday;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tanggal gajian'),
        content: StatefulBuilder(
          builder: (_, setState) => SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: 31,
              itemBuilder: (_, i) {
                final day = i + 1;
                return ListTile(
                  dense: true,
                  title: Text('Tanggal $day'),
                  trailing: selected == day
                      ? const Icon(Icons.check, color: FtColors.moss)
                      : null,
                  onTap: () => setState(() => selected = day),
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(firestoreProvider)
          .collection('households')
          .doc(household.id)
          .update({'payday': selected});
    }
  }

  Future<void> _editBudget(
    BuildContext context,
    WidgetRef ref,
    Household household,
  ) async {
    final ctrl = TextEditingController(
      text: household.monthlyBudgetTotal.toString(),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Anggaran bulanan'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: 'Rp ',
            hintText: '5000000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final v = int.tryParse(ctrl.text.replaceAll(RegExp(r'\D'), ''));
      if (v != null) {
        await ref
            .read(firestoreProvider)
            .collection('households')
            .doc(household.id)
            .update({'monthlyBudgetTotal': v});
      }
    }
    ctrl.dispose();
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({required this.household});
  final Household household;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Eyebrow('Anggota Keluarga'),
          ),
          for (var i = 0; i < household.members.length; i++) ...[
            if (i > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: parseColor(household.members[i].color),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initialsOf(household.members[i].displayName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          household.members[i].displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${roleToString(household.members[i].role)} · Bergabung ${Dates.short(household.members[i].joinedAt)}',
                          style: const TextStyle(
                              color: FtColors.ink3, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.child,
  });
  final String label;
  final String value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
              ),
              Text(
                value,
                style: const TextStyle(
                    color: FtColors.ink3, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.97,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? FtColors.ink : FtColors.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active ? FtColors.ink : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? FtColors.bg : FtColors.ink2,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.label,
    required this.detail,
    required this.onTap,
  });
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
            if (detail.isNotEmpty)
              Text(
                detail,
                style: const TextStyle(
                    color: FtColors.ink3, fontSize: 12),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 16, color: FtColors.ink4),
          ],
        ),
      ),
    );
  }
}
