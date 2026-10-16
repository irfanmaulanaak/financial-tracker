import 'package:flutter/material.dart';

import '../../../theme.dart';

/// Chip tanggal cepat — Hari ini / Kemarin / 2 hari lalu. Desain
/// "catch-up": kebanyakan orang mencatat rapel, bukan harian.
class QuickDateChips extends StatelessWidget {
  const QuickDateChips({super.key, required this.selected, required this.onPick});

  final DateTime selected;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final options = [
      (label: 'Hari ini', date: now),
      (label: 'Kemarin', date: now.subtract(const Duration(days: 1))),
      (label: '2 hari lalu', date: now.subtract(const Duration(days: 2))),
    ];
    final selKey = DateTime(selected.year, selected.month, selected.day);
    return Row(
      children: [
        for (final o in options) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onPick(o.date),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: DateTime(o.date.year, o.date.month, o.date.day) ==
                          selKey
                      ? FtColors.ink
                      : FtColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: FtColors.line, width: 0.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  o.label,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: DateTime(
                                o.date.year, o.date.month, o.date.day) ==
                            selKey
                        ? FtColors.bg
                        : FtColors.ink2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          if (o != options.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class CicilanLockedBanner extends StatelessWidget {
  const CicilanLockedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: FtColors.clay.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FtColors.clay.withValues(alpha: 0.24),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 16, color: FtColors.clay),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cicilan: hanya kategori, catatan, tanggal & pencatat yang bisa diubah. Hapus & catat ulang untuk ubah jumlah/kartu.',
              style: TextStyle(
                color: FtColors.ink2,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
