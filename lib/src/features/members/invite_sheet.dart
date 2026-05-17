import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_motion.dart';
import '../../ui/ft_ui.dart';
import '../household/household_repository.dart';

/// Invite bottom sheet — shell from `claude-design/screens-household.jsx`
/// `InviteMemberSheet`, but generates a single-use invite code instead of
/// the design's email/WA-by-contact flow. Keeps the existing security model
/// while matching the inline-from-Settings UX.
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Grabber(),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 6, 22, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Eyebrow('Undang Anggota'),
                    const SizedBox(height: 4),
                    Text(
                      'Tambah ke ${widget.householdName}',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontSize: 19, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bagikan kode satu kali ini ke anggota baru. Setelah masuk, transaksi mereka tergabung otomatis.',
                      style: TextStyle(
                        color: FtColors.ink3,
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_code == null)
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
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                    decoration: BoxDecoration(
                      color: FtColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: FtColors.lineStrong, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kode undangan (sekali pakai)',
                          style: TextStyle(
                            color: FtColors.ink3,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          _code!,
                          style: TextStyle(
                            fontFamily: 'Newsreader',
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 6,
                            color: FtColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: FtTapScale(
                                scale: 0.97,
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: _code!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Kode disalin'),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: FtColors.surface,
                                    border: Border.all(
                                        color: FtColors.line, width: 0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.copy_rounded,
                                          size: 14, color: FtColors.ink2),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Salin kode',
                                        style: TextStyle(
                                          color: FtColors.ink,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FtTapScale(
                                scale: 0.97,
                                onTap: () => setState(() => _code = null),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: FtColors.surface,
                                    border: Border.all(
                                        color: FtColors.line, width: 0.5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Buat ulang',
                                    style: TextStyle(
                                      color: FtColors.ink2,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
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
                  'Anggota dengan kode bisa mencatat pengeluaran, melihat saldo, dan menerima notifikasi anggaran bersama.',
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
    );
  }
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      child: Center(
        child: Container(
          width: 42,
          height: 5,
          decoration: BoxDecoration(
            color: FtColors.lineStrong,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
