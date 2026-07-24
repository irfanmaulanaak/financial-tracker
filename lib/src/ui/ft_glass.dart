import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'ft_glass_fx.dart';

/// Permukaan "liquid glass" untuk lapisan chrome (nav, sheet, rail).
///
/// Dua jalur render:
/// - Liquid OFF (default) atau high-contrast aktif → fallback solid yang
///   mereplikasi tampilan klasik persis (warna + alpha + blur opsional),
///   jadi zero regression saat beta dimatikan.
/// - Liquid ON → lapisan ringan untuk chrome:
///   1. satu blur backdrop + vibrancy ringan,
///   2. lensing — wallpaper liquid dilukis ulang dengan proyeksi membesar,
///      menekuk kuat di tepi (lihat `GlassLensLayer`),
///   3. tint tipis + sheen,
///   4. rim specular + fringe kromatik di tepi.
///
/// Kartu konten tidak memakai widget ini; glass hanya untuk nav dan sheet.
class FtGlass extends StatelessWidget {
  const FtGlass({
    super.key,
    required this.child,
    required this.borderRadius,
    this.baseColor,
    this.fallbackAlpha = 1.0,
    this.fallbackBlurSigma = 0,
    this.fallbackBorderColor,
    this.boxShadow,
    this.padding,
    this.animateIn = false,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Warna dasar permukaan; default `FtColors.surface`.
  final Color? baseColor;

  /// Alpha permukaan pada jalur fallback (klasik). Nav pakai 0.88.
  final double fallbackAlpha;

  /// Blur backdrop pada jalur fallback. Nav klasik pakai 18; sheet 0.
  final double fallbackBlurSigma;

  /// Border jalur fallback; null = tanpa border.
  final Color? fallbackBorderColor;

  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;

  /// Animasi masuk rim saat mount (liquid saja).
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final liquid = FtColors.liquid && !MediaQuery.highContrastOf(context);
    if (!liquid) return _fallback();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return _glass(context, animateRim: animateIn && !reduceMotion);
  }

  Widget _fallback() {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: (baseColor ?? FtColors.surface).withValues(alpha: fallbackAlpha),
        borderRadius: borderRadius,
        border: fallbackBorderColor == null
            ? null
            : Border.all(color: fallbackBorderColor!, width: 0.5),
        boxShadow: boxShadow,
      ),
      child: child,
    );
    if (fallbackBlurSigma <= 0) return box;
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: fallbackBlurSigma,
          sigmaY: fallbackBlurSigma,
        ),
        child: box,
      ),
    );
  }

  Widget _glass(BuildContext context, {required bool animateRim}) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    const sigma = 18.0;
    // Keep the material visibly transparent. The blur and rim provide
    // separation; tint is only a legibility assist.
    final tintAlpha = dark ? 0.18 : 0.12;
    final sheenAlpha = dark ? 0.08 : 0.14;

    // The backdrop subtree is isolated from the animated lens. A LiquidFrame
    // tick can now repaint the lens without invalidating the blur.
    final backdrop = RepaintBoundary(
      child: ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.compose(
            outer: const ColorFilter.matrix(_saturation118),
            inner: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: (baseColor ?? FtColors.surface).withValues(
                        alpha: tintAlpha,
                      ),
                      borderRadius: borderRadius,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: sheenAlpha),
                          (baseColor ?? FtColors.surface).withValues(
                            alpha: tintAlpha * 0.6,
                          ),
                        ],
                        stops: const [0, 0.5],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(padding: padding ?? EdgeInsets.zero, child: child),
            ],
          ),
        ),
      ),
    );

    final surface = Stack(
      children: [
        backdrop,
        Positioned.fill(
          child: RepaintBoundary(
            child: GlassLensLayer(borderRadius: borderRadius),
          ),
        ),
      ],
    );

    Widget glass;
    if (animateRim) {
      glass = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, opacity, staticSurface) => CustomPaint(
          foregroundPainter: _SpecularRimPainter(
            borderRadius: borderRadius,
            dark: dark,
            opacity: opacity,
          ),
          child: staticSurface,
        ),
        child: surface,
      );
    } else {
      glass = CustomPaint(
        foregroundPainter: _SpecularRimPainter(
          borderRadius: borderRadius,
          dark: dark,
          opacity: 1,
        ),
        child: surface,
      );
    }

    if (boxShadow != null) {
      glass = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: boxShadow,
        ),
        child: glass,
      );
    }
    return RepaintBoundary(child: glass);
  }
}

/// Mild vibrancy. Each RGB row sums to 1, so neutral content stays neutral.
const List<double> _saturation118 = [
  1.14172,
  -0.128736,
  -0.012984,
  0,
  0,
  -0.038268,
  1.051252,
  -0.012984,
  0,
  0,
  -0.038268,
  -0.128736,
  1.167004,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

/// Specular rim: light catches the top-left edge and fades across the surface.
class _SpecularRimPainter extends CustomPainter {
  const _SpecularRimPainter({
    required this.borderRadius,
    required this.dark,
    required this.opacity,
  });

  final BorderRadius borderRadius;
  final bool dark;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Cool outer edge picks up the app's action color very subtly.
    canvas.drawRRect(
      borderRadius.toRRect(rect).deflate(0.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = FtColors.clay.withValues(
          alpha: (dark ? 0.12 : 0.08) * opacity,
        ),
    );
    // Fringe dingin sedikit ke dalam.
    canvas.drawRRect(
      borderRadius.toRRect(rect).deflate(1.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..color = Colors.white.withValues(
          alpha: (dark ? 0.16 : 0.42) * opacity,
        ),
    );

    // Rim specular utama.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: (dark ? 0.62 : 0.92) * opacity),
          Colors.white.withValues(alpha: 0.06 * opacity),
          Colors.white.withValues(alpha: (dark ? 0.24 : 0.36) * opacity),
        ],
        stops: const [0, 0.55, 1],
      ).createShader(rect);
    canvas.drawRRect(borderRadius.toRRect(rect).deflate(0.8), paint);
  }

  @override
  bool shouldRepaint(_SpecularRimPainter old) =>
      old.dark != dark ||
      old.opacity != opacity ||
      old.borderRadius != borderRadius;
}
