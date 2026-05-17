import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({
    super.key,
    required this.dirty,
    required this.saving,
    required this.onTap,
  });
  final bool dirty;
  final bool saving;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.97,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: dirty ? FtColors.ink : FtColors.surfaceAlt,
          borderRadius: BorderRadius.circular(999),
        ),
        child: saving
            ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FtColors.bg,
                ),
              )
            : Text(
                'Simpan',
                style: TextStyle(
                  color: dirty ? FtColors.bg : FtColors.ink3,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }
}

class AvatarPreview extends StatelessWidget {
  const AvatarPreview({
    super.key,
    required this.initials,
    required this.color,
  });
  final String initials;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 24, 0, 18),
      child: Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              fontFamily: 'Newsreader',
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w500,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}

class AccentRow extends StatelessWidget {
  const AccentRow({
    super.key,
    required this.selectedHex,
    required this.options,
    required this.onPick,
  });
  final String selectedHex;
  final List<String> options;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Aksen Warna'),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final hex in options)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _AccentDot(
                    color: parseColor(hex),
                    active: hex == selectedHex,
                    onTap: () => onPick(hex),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.color,
    required this.active,
    required this.onTap,
  });
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.9,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: active ? FtColors.ink : Colors.transparent,
            width: 2,
          ),
        ),
        foregroundDecoration: active
            ? BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: FtColors.bg, width: 2),
              )
            : null,
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.nameCtrl,
    required this.email,
    required this.phone,
    required this.onNameChanged,
  });
  final TextEditingController nameCtrl;
  final String email;
  final String phone;
  final ValueChanged<String> onNameChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Informasi Pribadi'),
          const SizedBox(height: 8),
          FtCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _Field(
                  label: 'Nama',
                  child: TextField(
                    controller: nameCtrl,
                    onChanged: onNameChanged,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Nama lengkap',
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: TextStyle(color: FtColors.ink, fontSize: 14),
                  ),
                ),
                const Divider(height: 1),
                _Field(
                  label: 'Email',
                  child: Text(email,
                      style: TextStyle(color: FtColors.ink, fontSize: 14)),
                ),
                const Divider(height: 1),
                _Field(
                  label: 'No. Telepon',
                  child: Text(phone,
                      style: TextStyle(color: FtColors.ink, fontSize: 14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: FtColors.ink3,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }
}

class SecurityCard extends StatelessWidget {
  const SecurityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Keamanan'),
          const SizedBox(height: 8),
          FtCard(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            child: Column(
              children: const [
                _SecurityRow(
                  icon: Icons.shield_outlined,
                  label: 'Ubah kata sandi',
                  detail: 'Segera tersedia',
                ),
                Divider(height: 1),
                _SecurityRow(
                  icon: Icons.verified_user_outlined,
                  label: 'Autentikasi dua faktor',
                  detail: 'Segera tersedia',
                ),
                Divider(height: 1),
                _SecurityRow(
                  icon: Icons.devices_other_rounded,
                  label: 'Sesi aktif',
                  detail: 'Segera tersedia',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.label,
    required this.detail,
  });
  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: FtColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: FtColors.line, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 14, color: FtColors.ink2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(fontSize: 11, color: FtColors.ink3),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 14, color: FtColors.ink4),
        ],
      ),
    );
  }
}

String initialsFor(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final out = parts.take(2).map((w) => w[0]).join().toUpperCase();
  return out.isEmpty ? '?' : out;
}
