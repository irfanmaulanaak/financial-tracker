import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme.dart';
import '../../household/household.dart';

/// Welcome sheet sekali-tampil untuk anggota yang BARU bergabung lewat kode
/// undangan (pola Honeydue): jelaskan rumah tangganya, tingkat aksesnya,
/// dan satu ajakan aksi pertama.
Future<void> showOnboardingWelcomeSheet(
  BuildContext context, {
  required Household household,
  required Member member,
  required bool canRecord,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: FtColors.surface,
    isScrollControlled: true,
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
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: FtColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: FtColors.moss.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: FtColors.moss.withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: Icon(Icons.celebration_outlined,
                  size: 24, color: FtColors.moss),
            ),
            const SizedBox(height: 14),
            Text(
              'Selamat datang di ${household.name}.',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Semua catatan di sini milik bersama: pengeluaran, budget, '
              'tujuan, dan aset rumah tangga.',
              style: TextStyle(color: FtColors.ink2, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: FtColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: FtColors.line, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Akses kamu: ${accessLevelLabel(member.accessLevel)}',
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    accessLevelDetail(member.accessLevel),
                    style: TextStyle(
                        color: FtColors.ink3, fontSize: 11.5, height: 1.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (canRecord)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    GoRouter.of(context).push('/expenses/new');
                  },
                  child: const Text('Catat Pengeluaran Pertamamu'),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(canRecord ? 'Jelajahi dulu' : 'Mulai jelajahi'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
