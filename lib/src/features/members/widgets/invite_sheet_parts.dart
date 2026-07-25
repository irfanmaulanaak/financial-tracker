import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household.dart';

class InviteHeading extends StatelessWidget {
  const InviteHeading({super.key, required this.householdName});
  final String householdName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Undang Anggota'),
          const SizedBox(height: 4),
          Text(
            'Tambah ke $householdName',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontSize: 19, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Pilih peran dan tingkat akses, lalu bagikan kode satu kali ke anggota baru.',
            style: TextStyle(
              color: FtColors.ink3,
              fontSize: 11.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class RoleChip extends StatelessWidget {
  const RoleChip({
    super.key,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? FtColors.ink : FtColors.surface,
          borderRadius: BorderRadius.circular(999),
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

class AccessOption extends StatelessWidget {
  const AccessOption({
    super.key,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Radio(active: active),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    accessLevelLabel(level),
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    accessLevelDetail(level),
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 11,
                      height: 1.4,
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

class _Radio extends StatelessWidget {
  const _Radio({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(top: 2),
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
    );
  }
}

class GhostButton extends StatelessWidget {
  const GhostButton({
    super.key,
    this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData? icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: FtColors.surface,
          border: Border.all(color: FtColors.line, width: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: FtColors.ink2),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

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
