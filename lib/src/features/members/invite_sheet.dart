import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_motion.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_repository.dart';
import 'widgets/invite_sheet_parts.dart';

/// Invite bottom sheet — `claude-design/screens-household.jsx > InviteMemberSheet`.
/// Generates a single-use 128-bit invite token, pre-baked with the invited
/// member's role + access level. The joiner cannot escalate access beyond
/// what the invite carries.
class InviteMemberSheet extends ConsumerStatefulWidget {
  const InviteMemberSheet({
    super.key,
    required this.householdId,
    required this.householdName,
    required this.creatorUid,
  });
  final String householdId;
  final String householdName;
  final String creatorUid;

  static Future<void> show(
    BuildContext context, {
    required String householdId,
    required String householdName,
    required String creatorUid,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.32),
      builder: (_) => InviteMemberSheet(
        householdId: householdId,
        householdName: householdName,
        creatorUid: creatorUid,
      ),
    );
  }

  @override
  ConsumerState<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<InviteMemberSheet> {
  MemberRole _role = MemberRole.suami;
  AccessLevel _access = AccessLevel.full;
  String? _code;
  bool _busy = false;
  String? _error;

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await ref.read(householdRepositoryProvider).createInvite(
            householdId: widget.householdId,
            generatedBy: widget.creatorUid,
            role: _role,
            accessLevel: _access,
          );
      FtHaptics.success();
      setState(() => _code = code);
    } catch (e) {
      FtHaptics.error();
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final padding = MediaQuery.paddingOf(context);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: FtColors.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(top: 10, bottom: padding.bottom + 18),
        child: FtFadeUp(
          duration: const Duration(milliseconds: 260),
          distance: 14,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SheetGrabber(),
                InviteHeading(householdName: widget.householdName),
                const SizedBox(height: 14),
                if (_code == null) ..._configBody() else ..._codeBody(),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Text(
                      _error!,
                      style: TextStyle(color: FtColors.danger, fontSize: 11),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Text(
                    'Kode kedaluwarsa otomatis dalam 24 jam dan hanya bisa dipakai sekali.',
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 10.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _configBody() {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Peran'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final r in MemberRole.values)
                  RoleChip(
                    label: roleToString(r),
                    active: _role == r,
                    onTap: () => setState(() => _role = r),
                  ),
              ],
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Tingkat akses'),
            const SizedBox(height: 6),
            for (final lvl in AccessLevel.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: AccessOption(
                  level: lvl,
                  active: _access == lvl,
                  onTap: () => setState(() => _access = lvl),
                ),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
        child: FtTapScale(
          scale: 0.97,
          onTap: _busy ? null : _generate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: FtColors.ink,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: _busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: FtColors.bg,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 14, color: FtColors.bg),
                      const SizedBox(width: 8),
                      Text(
                        'Buat Kode Undangan',
                        style: TextStyle(
                          color: FtColors.bg,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _codeBody() {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          decoration: BoxDecoration(
            color: FtColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: FtColors.lineStrong, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${roleToString(_role)} · ${accessLevelLabel(_access)}',
                style: TextStyle(color: FtColors.ink3, fontSize: 11),
              ),
              const SizedBox(height: 8),
              SelectableText(
                _code!,
                style: TextStyle(
                  fontFamily: 'Menlo',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: FtColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      icon: Icons.copy_rounded,
                      label: 'Salin kode',
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: _code!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kode disalin')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GhostButton(
                      label: 'Buat ulang',
                      onTap: () => setState(() => _code = null),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ];
  }
}
