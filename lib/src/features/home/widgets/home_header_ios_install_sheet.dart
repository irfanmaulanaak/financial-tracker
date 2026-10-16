import 'package:flutter/material.dart';

import '../../../theme.dart';

/// iOS Safari can't be triggered programmatically — show the manual
/// "Share → Add to Home Screen" flow instead.
Future<void> showIosInstructions(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: FtColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          22,
          18,
          22,
          18 + MediaQuery.viewPaddingOf(ctx).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: FtColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Pasang sebagai app',
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Di Safari, ikuti langkah berikut agar FinSist tampil seperti app:',
              style: TextStyle(color: FtColors.ink3, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 14),
            _Step(
              n: 1,
              icon: Icons.ios_share_rounded,
              text: 'Ketuk tombol Bagikan di bagian bawah Safari.',
            ),
            _Step(
              n: 2,
              icon: Icons.add_box_outlined,
              text: 'Pilih “Tambahkan ke Layar Utama”.',
            ),
            _Step(
              n: 3,
              icon: Icons.check_rounded,
              text: 'Ketuk “Tambah”. Ikon FinSist akan muncul di home screen.',
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Mengerti'),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _Step extends StatelessWidget {
  const _Step({required this.n, required this.icon, required this.text});
  final int n;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: FtColors.surfaceAlt,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$n',
              style: TextStyle(
                color: FtColors.ink2,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Icon(icon, color: FtColors.ink2, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: FtColors.ink, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
