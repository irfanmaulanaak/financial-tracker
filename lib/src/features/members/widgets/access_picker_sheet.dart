import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household.dart';

/// Bottom sheet that lets the creator pick a new access tier for a member.
/// Returns the chosen [AccessLevel] or null if the user dismisses.
class AccessPickerSheet extends StatefulWidget {
  const AccessPickerSheet({super.key, required this.current});
  final AccessLevel current;

  static Future<AccessLevel?> show(
    BuildContext context, {
    required AccessLevel current,
  }) {
    return showModalBottomSheet<AccessLevel>(
      context: context,
      backgroundColor: FtColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => AccessPickerSheet(current: current),
    );
  }

  @override
  State<AccessPickerSheet> createState() => _AccessPickerSheetState();
}

class _AccessPickerSheetState extends State<AccessPickerSheet> {
  late AccessLevel _picked = widget.current;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Eyebrow('Tingkat Akses'),
            const SizedBox(height: 12),
            for (final lvl in AccessLevel.values) ...[
              _PickerRow(
                level: lvl,
                active: _picked == lvl,
                onTap: () => setState(() => _picked = lvl),
              ),
              if (lvl != AccessLevel.values.last) const SizedBox(height: 8),
            ],
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () => Navigator.pop(context, _picked),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.level,
    required this.active,
    required this.onTap,
  });
  final AccessLevel level;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.99,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: active
              ? FtColors.clay.withValues(alpha: 0.10)
              : FtColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? FtColors.clay : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active ? FtColors.clay : Colors.transparent,
                    border: Border.all(
                      color: active ? FtColors.clay : FtColors.lineStrong,
                      width: 1.5,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: active
                      ? Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    accessLevelLabel(level),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                accessLevelDetail(level),
                style: TextStyle(
                  fontSize: 11,
                  color: FtColors.ink3,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
