import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/invite_code.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_repository.dart';
import '../household/name_format.dart';
import 'onboarding_state.dart';

class JoinHouseholdScreen extends ConsumerStatefulWidget {
  const JoinHouseholdScreen({super.key});

  @override
  ConsumerState<JoinHouseholdScreen> createState() =>
      _JoinHouseholdScreenState();
}

class _JoinHouseholdScreenState extends ConsumerState<JoinHouseholdScreen> {
  final _codeCtrl = TextEditingController();
  MemberRole _role = MemberRole.istri;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    final code = InviteCode.normalise(_codeCtrl.text);
    if (!InviteCode.isValid(code)) {
      setState(() => _error = 'Kode harus 6 digit angka');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(householdRepositoryProvider)
          .joinWithInvite(
            code: code,
            userId: user.uid,
            displayName: prettyName(user.displayName ?? user.email ?? ''),
            role: _role,
          );
      // Anggota baru: welcome sheet sekali + checklist mulai. Hanya
      // ter-trigger di sini, jadi user lama tidak pernah melihatnya.
      await ref.read(onboardingProvider.notifier).startJoiner();
      if (mounted) context.go('/home');
    } on StateError catch (e) {
      setState(() => _error = _friendlyError(e.message));
    } catch (e) {
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: FtPageContainer(
        child: Column(
          children: [
            FtSubHeader(
              title: 'Gabung rumah tangga',
              onBack: () => context.go('/landing'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                children: [
                  FtCard(
                    child: Column(
                      children: [
                        const Eyebrow('Kode undangan'),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          style: const TextStyle(
                            fontSize: 28,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: '000000',
                            counterText: '',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Peran kamu',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MemberRole>(
                    initialValue: _role,
                    items: MemberRole.values
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(roleToString(r)),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _role = v ?? _role),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _join,
                    child: _busy
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Gabung'),
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

String _friendlyError(String code) => switch (code) {
  'invite_not_found' => 'Kode tidak ditemukan',
  'invite_consumed' => 'Kode sudah pernah dipakai',
  'invite_expired' => 'Kode sudah kedaluwarsa',
  'household_missing' => 'Rumah tangga tidak ditemukan',
  'user_already_in_household' => 'Kamu sudah tergabung di rumah tangga',
  'already_member' => 'Kamu sudah menjadi anggota',
  _ => 'Gagal: $code',
};
