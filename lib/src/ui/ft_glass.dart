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
/// - Liquid ON → tumpukan lapisan ala material iOS 26:
///   1. blur backdrop + boost saturasi (vibrancy),
///   2. lensing — wallpaper liquid dilukis ulang dengan proyeksi membesar,
///      menekuk kuat di tepi (lihat `GlassLensLayer`),
///   3. tint tipis + sheen,
///   4. kilau sweep periodik + touch-point glow interaktif,
///   5. rim specular + fringe kromatik di tepi.
///
/// Chrome (nav/sheet) pakai jalur penuh; kartu konten pakai [lite] supaya
/// list panjang tetap ringan (tanpa BackdropFilter per kartu).
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
    this.sweep = false,
    this.animateIn = false,
    this.lite = false,
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

  /// Kilau specular berjalan (liquid saja; hormati reduce-motion).
  final bool sweep;

  /// Animasi masuk: blur + tint naik 0→penuh saat mount (liquid saja).
  final bool animateIn;

  /// Mode ringan untuk kartu konten: tanpa BackdropFilter (mahal di list),
  /// lensa wallpaper versi sederhana + tint lebih pekat agar teks terbaca.
  final bool lite;

  @override
  Widget build(BuildContext context) {
    final liquid = FtColors.liquid && !MediaQuery.highContrastOf(context);
    if (!liquid) return _fallback();

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (animateIn && !reduceMotion) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) => _glass(context, t, reduceMotion),
      );
    }
    return _glass(context, 1, reduceMotion);
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

  Widget _glass(BuildContext context, double t, bool reduceMotion) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final sigma = 26.0 * t;
    // Tint tipis — biarkan warna background tembus; vibrancy datang dari
    // boost saturasi di filter + lapisan lensa, bukan permukaan yang pekat.
    // Kartu (lite) menampung angka/teks utama → tint lebih pekat.
    final tintAlpha = (lite ? (dark ? 0.50 : 0.58) : (dark ? 0.26 : 0.30)) * t;
    final sheenAlpha = (dark ? 0.10 : 0.18) * t;

    final layers = Stack(
      children: [
        // 2) Lensing: wallpaper diproyeksi membesar, menekuk di tepi.
        if (t > 0.6)
          Positioned.fill(
            child: GlassLensLayer(borderRadius: borderRadius, lite: lite),
          ),
        // 3) Tint + sheen.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    (baseColor ?? FtColors.surface).withValues(alpha: tintAlpha),
                borderRadius: borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: sheenAlpha),
                    (baseColor ?? FtColors.surface)
                        .withValues(alpha: tintAlpha * 0.6),
                  ],
                  stops: const [0, 0.5],
                ),
              ),
            ),
          ),
        ),
        // 4) Kilau periodik.
        if (sweep && !reduceMotion)
          Positioned.fill(
            child: IgnorePointer(child: GlassSweep(dark: dark)),
          ),
        Padding(
          padding: padding ?? EdgeInsets.zero,
          child: child,
        ),
        // Glow interaktif paling atas: cahaya jatuh di muka kaca, event
        // tetap tembus ke tombol di bawahnya (listener translucent).
        if (!reduceMotion) Positioned.fill(child: GlassTouchGlow(dark: dark)),
      ],
    );

    // 1) Blur + saturasi pada konten nyata yang lewat di belakang kaca.
    // Lite: lewati BackdropFilter — di belakang kartu hanya ada wallpaper,
    // dan lapisan lensa sudah melukisnya ulang, jadi visual tetap "kaca".
    Widget glass = ClipRRect(
      borderRadius: borderRadius,
      child: lite
          ? layers
          : BackdropFilter(
              filter: ImageFilter.compose(
                outer: const ColorFilter.matrix(_saturation135),
                inner: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              ),
              child: layers,
            ),
    );

    // 5) Rim specular + fringe kromatik.
    glass = CustomPaint(
      foregroundPainter: _SpecularRimPainter(
        borderRadius: borderRadius,
        dark: dark,
        opacity: t,
      ),
      child: glass,
    );

    if (boxShadow == null) return glass;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: glass,
    );
  }
}

/// Matriks saturasi 1.35 (preserve luminance Rec. 709); tiap baris RGB
/// berjumlah 1 supaya abu-abu tetap abu-abu.
const List<double> _saturation135 = [
  1.275590, -0.250320, -0.025270, 0, 0, //
  -0.074410, 1.099680, -0.025270, 0, 0, //
  -0.074410, -0.250320, 1.324730, 0, 0, //
  0, 0, 0, 1, 0,
];

/// Rim specular: stroke gradient terang di kiri-atas → gelap di kanan-bawah,
/// meniru pantulan cahaya di tepi kaca, plus fringe kromatik tipis
/// (hangat di luar, dingin di dalam) sebagai ilusi dispersi lensa.
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

    // Fringe hangat di tepi terluar.
    canvas.drawRRect(
      borderRadius.toRRect(rect).deflate(0.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFFFFB478)
            .withValues(alpha: (dark ? 0.10 : 0.16) * opacity),
    );
    // Fringe dingin sedikit ke dalam.
    canvas.drawRRect(
      borderRadius.toRRect(rect).deflate(1.6),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0xFF78B4FF)
            .withValues(alpha: (dark ? 0.09 : 0.14) * opacity),
    );

    // Rim specular utama.
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: (dark ? 0.55 : 0.95) * opacity),
          Colors.white.withValues(alpha: 0.08 * opacity),
          Colors.white.withValues(alpha: (dark ? 0.30 : 0.55) * opacity),
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
