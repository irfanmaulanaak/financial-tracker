import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../ui/ft_motion.dart';

/// Shared editorial chrome for sign-in / sign-up / email-link screens.
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.eyebrow,
    required this.headline,
    required this.subtitle,
    required this.children,
    this.quietFooter,
  });

  final String eyebrow;
  final String headline;
  final String subtitle;
  final List<Widget> children;
  final Widget? quietFooter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, box) {
            final tight = box.maxHeight < 720;
            return Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: tight ? 20 : 36,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: FtFadeUp(
                    duration: const Duration(milliseconds: 360),
                    distance: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _BrandMark(),
                        SizedBox(height: tight ? 36 : 48),
                        Eyebrow(eyebrow, color: FtColors.clay),
                        const SizedBox(height: 14),
                        Text(
                          headline,
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(
                                fontSize: tight ? 38 : 44,
                                height: 1.05,
                                letterSpacing: -1.4,
                                color: FtColors.ink,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: FtColors.ink3,
                            fontSize: 14,
                            height: 1.55,
                          ),
                        ),
                        SizedBox(height: tight ? 28 : 36),
                        ...children,
                        if (quietFooter != null) ...[
                          const SizedBox(height: 28),
                          Center(child: quietFooter!),
                        ],
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: FtColors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: FtColors.lineStrong, width: 0.5),
          ),
          alignment: Alignment.center,
          child: Text(
            'ft',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                  letterSpacing: 0.3,
                  color: FtColors.clay,
                  height: 1,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Financial Tracker',
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'untuk keluarga · IDR',
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 10.5,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Quiet inline error band shown above the primary action.
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FtColors.danger.withValues(alpha: 0.06),
        border: Border.all(
            color: FtColors.danger.withValues(alpha: 0.25), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: FtColors.danger, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: FtColors.danger,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline success/info band (cream/sage), used by passwordless link flow.
class AuthInfoBanner extends StatelessWidget {
  const AuthInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.mark_email_read_outlined,
  });
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FtColors.sage.withValues(alpha: 0.08),
        border: Border.all(
            color: FtColors.sage.withValues(alpha: 0.3), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FtColors.moss, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: FtColors.moss,
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle "—— atau ——" divider used between primary CTA + Google button.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: const [
          Expanded(child: Divider(color: FtColors.line, thickness: 0.5)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              'atau',
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(child: Divider(color: FtColors.line, thickness: 0.5)),
        ],
      ),
    );
  }
}

/// Kept for backwards-compat (sign-in/up/email-link migrated to FtInput).
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Eyebrow(label),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
