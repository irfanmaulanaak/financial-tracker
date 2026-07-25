import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_ui.dart';
import '../auth/auth_repository.dart';
import '../home/widgets/home_formatters.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/household_repository.dart';
import '../household/name_format.dart';
import 'widgets/edit_profile_parts.dart';

/// Edit Profile screen — `claude-design/screens-profile.jsx > EditProfileScreen`.
/// Lets the signed-in user edit their display name + accent color (mirrored
/// to `households/{hid}.members[<self>]`). Email/phone fields render as
/// info-only rows since the auth provider is the source of truth there.
/// Security rows render as static UI for MVP.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  String _color = '#C4612A';
  bool _dirty = false;
  bool _saving = false;

  static const _colorOptions = [
    '#C4612A', // clay
    '#5E7A64', // sage
    '#3A6075', // sky
    '#7A3F4E', // plum
    '#B89030', // ochre
    '#2D5040', // moss
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(User user, Household household) async {
    setState(() => _saving = true);
    try {
      final newName = _nameCtrl.text.trim();
      await ref.read(householdRepositoryProvider).updateMyProfile(
            householdId: household.id,
            userId: user.uid,
            displayName: newName.isEmpty ? null : newName,
            color: _color,
          );
      if (newName.isNotEmpty && newName != user.displayName) {
        await user.updateDisplayName(newName);
      }
      FtHaptics.success();
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      showFtErrorSnack(context, e, prefix: 'Gagal menyimpan');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: const Text(
          'Akun Firebase akan dihapus permanen. Data rumah tangga tetap untuk anggota lain.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: FtColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authRepositoryProvider).deleteCurrentUser();
    } catch (e) {
      if (!mounted) return;
      showFtErrorSnack(context, e, prefix: 'Gagal hapus akun');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final household = ref.watch(currentHouseholdProvider).value;
    if (user == null || household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final me = household.memberOf(user.uid);
    if (!_dirty) {
      _nameCtrl.text = prettyName(user.displayName ?? user.email ?? 'User');
      _color = me?.color ?? '#C4612A';
    }
    final accent = parseColor(_color);

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            FtSubHeader(
              title: 'Edit Profil',
              trailing: SaveButton(
                dirty: _dirty,
                saving: _saving,
                onTap: _dirty ? () => _save(user, household) : null,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  AvatarPreview(
                    initials: initialsFor(_nameCtrl.text),
                    color: accent,
                  ),
                  AccentRow(
                    selectedHex: _color,
                    options: _colorOptions,
                    onPick: (hex) {
                      setState(() {
                        _color = hex;
                        _dirty = true;
                      });
                    },
                  ),
                  InfoCard(
                    nameCtrl: _nameCtrl,
                    email: user.email ?? '-',
                    phone: user.phoneNumber ?? '-',
                    onNameChanged: (_) => setState(() => _dirty = true),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                    child: OutlinedButton(
                      onPressed: _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FtColors.danger,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: const Text('Hapus Akun'),
                    ),
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
