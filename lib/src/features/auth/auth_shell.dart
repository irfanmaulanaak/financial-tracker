import 'package:flutter/material.dart';

import '../../theme.dart';

/// Shared editorial chrome for sign-in / sign-up screens.
/// - cream background, generous top padding
/// - small eyebrow line + serif headline + supporting subtitle
/// - kids = the form & primary action stack
/// - quietFooter = secondary nav text below
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  _BrandMark(),
                  const SizedBox(height: 36),
                  Eyebrow(eyebrow),
                  const SizedBox(height: 10),
                  Text(
                    headline,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          height: 1.05,
                          fontSize: 36,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: FtColors.ink3,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  ...children,
                  if (quietFooter != null) ...[
                    const SizedBox(height: 22),
                    Center(child: quietFooter),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: FtColors.surfaceAlt,
            shape: BoxShape.circle,
            border: Border.all(color: FtColors.lineStrong, width: 0.5),
          ),
          alignment: Alignment.center,
          child: Text(
            'ft',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  letterSpacing: 0.5,
                  color: FtColors.ink,
                ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          'Financial Tracker',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: FtColors.ink2,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

/// Field with an eyebrow-style label above the input (matches design ref).
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
  });
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

/// Quiet "—— atau ——" divider used between primary CTA + Google button.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          const Expanded(child: Divider(color: FtColors.line, thickness: 0.5)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'atau',
              style: TextStyle(
                color: FtColors.ink3,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const Expanded(child: Divider(color: FtColors.line, thickness: 0.5)),
        ],
      ),
    );
  }
}
