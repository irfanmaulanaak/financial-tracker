import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Background global tema Liquid: warna dasar `FtColors.bg` + blob gradient
/// aksen yang drift pelan (loop mulus 20 detik). Dipasang sekali di
/// `app.dart` di belakang Navigator; semua Scaffold transparan saat liquid
/// sehingga background ini terlihat menerus antar layar.
///
/// Juga memasang [LiquidScene] supaya permukaan kaca (`FtGlass`) bisa
/// menggambar ulang wallpaper yang sama dengan proyeksi lensa (refraksi).
///
/// Liquid OFF → langsung mengembalikan child (tanpa Stack, tanpa ticker).
class FtLiquidBackground extends StatefulWidget {
  const FtLiquidBackground({super.key, required this.child});

  final Widget child;

  @override
  State<FtLiquidBackground> createState() => _FtLiquidBackgroundState();
}

class _FtLiquidBackgroundState extends State<FtLiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liquid = FtColors.liquid;
    final animate = liquid && !MediaQuery.disableAnimationsOf(context);
    // Sinkron ticker dengan status liquid — build ini ikut terpicu oleh
    // ftRebuildAllWidgets() saat toggle di Settings di-flip.
    if (animate && !_ctrl.isAnimating) _ctrl.repeat();
    if (!animate && _ctrl.isAnimating) _ctrl.stop();

    if (!liquid) return widget.child;

    final dark = Theme.of(context).brightness == Brightness.dark;
    return LiquidScene(
      controller: _ctrl,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _ctrl,
                builder: (_, _) => CustomPaint(
                  painter: _ScenePainter(t: _ctrl.value, dark: dark),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Scope yang membagikan jam animasi wallpaper ke permukaan kaca, supaya
/// kaca bisa melukis ulang scene yang identik (untuk efek lensa/refraksi).
class LiquidScene extends InheritedWidget {
  const LiquidScene({
    super.key,
    required this.controller,
    required super.child,
  });

  final AnimationController controller;

  static LiquidScene? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiquidScene>();

  /// Lukis wallpaper liquid utuh untuk layar seukuran [size] pada waktu [t].
  /// Dipakai background global DAN lapisan lensa di FtGlass.
  static void paintScene(Canvas canvas, Size size, double t, bool dark) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = FtColors.bg);

    // Wash diagonal supaya dasar tidak flat di area tanpa blob.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FtColors.bgAlt.withValues(alpha: dark ? 0.6 : 0.7),
            FtColors.bgAlt.withValues(alpha: 0),
            FtColors.bgAlt.withValues(alpha: dark ? 0.4 : 0.5),
          ],
        ).createShader(rect),
    );

    // Aksen palette sudah punya varian gelap/terang sendiri di FtColors.
    final colors = [
      FtColors.clay,
      FtColors.sky,
      FtColors.ochre,
      FtColors.sage,
      FtColors.plum,
      FtColors.sky,
    ];
    const twoPi = 2 * math.pi;
    for (var i = 0; i < _specs.length; i++) {
      final b = _specs[i];
      final cx =
          (b.cx + b.ax * math.sin(twoPi * b.freq * t + b.phase)) * size.width;
      final cy =
          (b.cy + b.ay * math.cos(twoPi * b.freq * t + b.phase)) * size.height;
      final r = size.shortestSide * b.r;
      final color = colors[i].withValues(
        alpha: dark ? b.alphaDark : b.alphaLight,
      );
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: r),
          ),
      );
    }
  }

  @override
  bool updateShouldNotify(LiquidScene old) => controller != old.controller;
}

class _BlobSpec {
  const _BlobSpec({
    required this.cx,
    required this.cy,
    required this.r,
    required this.ax,
    required this.ay,
    required this.phase,
    required this.alphaLight,
    required this.alphaDark,
    this.freq = 1,
  });

  final double cx, cy; // pusat (fraksi lebar/tinggi)
  final double r; // radius (fraksi sisi terpendek)
  final double ax, ay; // amplitudo drift (fraksi)
  final double phase;
  final double alphaLight, alphaDark;
  final double freq; // siklus per loop — bilangan bulat agar loop mulus
}

// Vivid ala wallpaper demo Apple: blob besar saling tumpang tindih, warna
// hangat-dingin berselang supaya tidak muddy. Dark butuh alpha lebih tinggi
// karena warna tenggelam di dasar gelap.
const _specs = [
  _BlobSpec(
      cx: 0.88, cy: 0.05, r: 0.70, ax: 0.14, ay: 0.10,
      phase: 0, alphaLight: 0.46, alphaDark: 0.50),
  _BlobSpec(
      cx: 0.02, cy: 0.32, r: 0.75, ax: 0.12, ay: 0.14,
      phase: 2.1, alphaLight: 0.38, alphaDark: 0.44, freq: 2),
  _BlobSpec(
      cx: 0.70, cy: 0.92, r: 0.65, ax: 0.15, ay: 0.10,
      phase: 4.2, alphaLight: 0.38, alphaDark: 0.40),
  _BlobSpec(
      cx: 0.22, cy: -0.05, r: 0.55, ax: 0.10, ay: 0.09,
      phase: 1.0, alphaLight: 0.32, alphaDark: 0.38, freq: 2),
  _BlobSpec(
      cx: 0.12, cy: 0.95, r: 0.55, ax: 0.12, ay: 0.11,
      phase: 5.3, alphaLight: 0.30, alphaDark: 0.34),
  // Pengisi tengah — area mati antara blob pinggir tetap hidup.
  _BlobSpec(
      cx: 0.45, cy: 0.55, r: 0.50, ax: 0.16, ay: 0.13,
      phase: 3.4, alphaLight: 0.22, alphaDark: 0.30, freq: 1),
];

class _ScenePainter extends CustomPainter {
  const _ScenePainter({required this.t, required this.dark});

  final double t;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) =>
      LiquidScene.paintScene(canvas, size, t, dark);

  @override
  bool shouldRepaint(_ScenePainter old) => old.t != t || old.dark != dark;
}
