import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'ft_liquid_background.dart';

/// Lapisan "lensing" — inti tampilan Liquid Glass.
///
/// Wallpaper liquid bersifat prosedural (posisi blob diketahui tiap frame),
/// jadi alih-alih sampling backdrop (butuh shader, tak jalan di web), kaca
/// melukis ulang scene yang sama dengan dua proyeksi:
/// - seluruh bidang diperbesar ~1.10 (lensa dasar), dan
/// - cincin tepi diperbesar ~1.35 → background tampak membelok ke dalam di
///   tepi, persis perilaku lensa cembung (tengah datar, tepi menekuk kuat).
class GlassLensLayer extends StatefulWidget {
  const GlassLensLayer({
    super.key,
    required this.borderRadius,
    this.lite = false,
  });

  final BorderRadius borderRadius;

  /// Versi murah untuk kartu: satu proyeksi tanpa saveLayer/cincin tepi —
  /// aman dipakai berulang dalam list panjang.
  final bool lite;

  @override
  State<GlassLensLayer> createState() => _GlassLensLayerState();
}

class _GlassLensLayerState extends State<GlassLensLayer> {
  Offset? _origin;

  void _measure() {
    if (!mounted) return;
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return;
    final o = box.localToGlobal(Offset.zero);
    if (o != _origin) setState(() => _origin = o);
  }

  @override
  Widget build(BuildContext context) {
    final scene = LiquidScene.maybeOf(context);
    if (scene == null) return const SizedBox.shrink();

    // Posisi global dibutuhkan untuk memetakan wallpaper layar-penuh ke
    // koordinat lokal kaca; diukur ulang tiap frame layout (konvergen sekali
    // chrome diam — hanya berubah saat sheet meluncur/resize).
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    if (_origin == null) return const SizedBox.shrink();

    final dark = Theme.of(context).brightness == Brightness.dark;
    final screen = MediaQuery.sizeOf(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: scene.controller,
        builder: (_, _) {
          // Ukur ulang tiap tick — posisi berubah saat sheet meluncur naik
          // tanpa memicu rebuild widget ini.
          WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
          return CustomPaint(
            painter: _LensPainter(
              t: scene.controller.value,
              dark: dark,
              origin: _origin!,
              screen: screen,
              borderRadius: widget.borderRadius,
              lite: widget.lite,
            ),
          );
        },
      ),
    );
  }
}

class _LensPainter extends CustomPainter {
  const _LensPainter({
    required this.t,
    required this.dark,
    required this.origin,
    required this.screen,
    required this.borderRadius,
    this.lite = false,
  });

  final double t;
  final bool dark;
  final Offset origin;
  final Size screen;
  final BorderRadius borderRadius;
  final bool lite;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    final center = origin + Offset(size.width / 2, size.height / 2);

    void drawZone(Path clip, double magnify, {double? alpha}) {
      canvas.save();
      canvas.clipPath(clip);
      // saveLayer hanya saat butuh meredupkan scene (jalur chrome) — mahal,
      // dilewati di jalur lite.
      if (alpha != null) {
        canvas.saveLayer(
          rect,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
      }
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(magnify);
      canvas.translate(-center.dx, -center.dy);
      LiquidScene.paintScene(canvas, screen, t, dark);
      if (alpha != null) canvas.restore();
      canvas.restore();
    }

    if (lite) {
      // Kartu: satu proyeksi penuh; tint pekat dari FtGlass yang menjaga
      // keterbacaan teks di atasnya.
      drawZone(Path()..addRRect(rrect), 1.07);
      return;
    }

    // Lensa dasar — seluruh bidang sedikit diperbesar.
    drawZone(Path()..addRRect(rrect), 1.10, alpha: 0.55);

    // Cincin tepi — pembesaran kuat = background "menekuk" masuk.
    final inset = math.min(size.shortestSide * 0.20, 16.0);
    final ring = Path.combine(
      PathOperation.difference,
      Path()..addRRect(rrect),
      Path()..addRRect(rrect.deflate(inset)),
    );
    drawZone(ring, 1.35, alpha: 0.70);

    // Vignette tipis di dalam tepi — kesan ketebalan kaca.
    canvas.drawRRect(
      rrect.deflate(inset / 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = inset
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, inset / 2)
        ..color = Colors.black.withValues(alpha: dark ? 0.10 : 0.05),
    );
  }

  @override
  bool shouldRepaint(_LensPainter old) =>
      old.t != t ||
      old.dark != dark ||
      old.origin != origin ||
      old.screen != screen ||
      old.borderRadius != borderRadius ||
      old.lite != lite;
}

/// Touch-point illumination: kaca menyala di titik sentuh/hover dan meredup
/// saat dilepas — meniru perilaku interaktif Liquid Glass.
class GlassTouchGlow extends StatefulWidget {
  const GlassTouchGlow({super.key, required this.dark});

  final bool dark;

  @override
  State<GlassTouchGlow> createState() => _GlassTouchGlowState();
}

class _GlassTouchGlowState extends State<GlassTouchGlow> {
  Offset? _pos;
  bool _active = false;

  void _set(Offset pos, bool active) {
    setState(() {
      _pos = pos;
      _active = active;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      opaque: false,
      onHover: (e) => _set(e.localPosition, true),
      onExit: (_) => setState(() => _active = false),
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (e) => _set(e.localPosition, true),
        onPointerMove: (e) => _set(e.localPosition, true),
        onPointerUp: (_) => setState(() => _active = false),
        onPointerCancel: (_) => setState(() => _active = false),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: _active ? 1.0 : 0.0),
          duration: Duration(milliseconds: _active ? 120 : 450),
          curve: Curves.easeOut,
          builder: (_, o, _) {
            if (_pos == null || o == 0) return const SizedBox.expand();
            return CustomPaint(
              painter: _GlowPainter(pos: _pos!, opacity: o, dark: widget.dark),
            );
          },
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter({
    required this.pos,
    required this.opacity,
    required this.dark,
  });

  final Offset pos;
  final double opacity;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    void glow(double radius, double alpha) {
      canvas.drawCircle(
        pos,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: alpha * opacity),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: pos, radius: radius)),
      );
    }

    glow(120, dark ? 0.12 : 0.16);
    glow(40, dark ? 0.18 : 0.24);
  }

  @override
  bool shouldRepaint(_GlowPainter old) =>
      old.pos != pos || old.opacity != opacity || old.dark != dark;
}

/// Pita highlight diagonal yang menyapu permukaan tiap ~7 detik, lalu parkir
/// di luar bidang (tak terlihat) sampai siklus berikutnya.
class GlassSweep extends StatefulWidget {
  const GlassSweep({super.key, required this.dark});

  final bool dark;

  @override
  State<GlassSweep> createState() => _GlassSweepState();
}

class _GlassSweepState extends State<GlassSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final band = FractionallySizedBox(
      widthFactor: 0.5,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            transform: const GradientRotation(-0.5),
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white.withValues(alpha: widget.dark ? 0.09 : 0.15),
              Colors.white.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );

    return ClipRect(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          // Sapuan terjadi di 22% pertama siklus; sisanya idle di luar tepi.
          final t = const Interval(0, 0.22, curve: Curves.easeInOut)
              .transform(_ctrl.value);
          return Align(
            alignment: Alignment(lerpDouble(-3.0, 3.0, t)!, 0),
            child: band,
          );
        },
      ),
    );
  }
}
