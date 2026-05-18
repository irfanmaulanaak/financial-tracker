import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/invite_code.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_repository.dart';
import '../household/name_format.dart';

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
      setState(() => _error = 'Kode undangan tidak valid');
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
                          keyboardType: TextInputType.visiblePassword,
                          autocorrect: false,
                          enableSuggestions: false,
                          maxLength: InviteCode.length,
                          style: const TextStyle(
                            fontFamily: 'Menlo',
                            fontSize: 18,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            hintText: 'Tempel kode di sini',
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
