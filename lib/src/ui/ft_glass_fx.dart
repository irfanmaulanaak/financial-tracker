import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'ft_liquid_background.dart';

/// Lapisan "lensing" — inti tampilan Liquid Glass.
///
/// Wallpaper liquid sudah dirender sekali per langkah (~15 fps) ke image
/// bersama di [LiquidFrame], jadi kaca tinggal men-blit image itu dengan
/// dua proyeksi (drawImageRect — murah, tanpa shader/saveLayer per frame):
/// - seluruh bidang diperbesar ~1.10 (lensa dasar), dan
/// - cincin tepi diperbesar ~1.35 → background tampak membelok ke dalam di
///   tepi, persis perilaku lensa cembung (tengah datar, tepi menekuk kuat).
class GlassLensLayer extends StatelessWidget {
  const GlassLensLayer({
    super.key,
    required this.borderRadius,
    this.lite = false,
  });

  final BorderRadius borderRadius;

  /// Versi murah untuk kartu: satu proyeksi tanpa cincin tepi/vignette —
  /// aman dipakai berulang dalam list panjang.
  final bool lite;

  @override
  Widget build(BuildContext context) {
    final scene = LiquidScene.maybeOf(context);
    if (scene == null) return const SizedBox.shrink();

    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: CustomPaint(
        painter: _LensPainter(
          frame: scene.frame,
          dark: dark,
          borderRadius: borderRadius,
          lite: lite,
        ),
      ),
    );
  }
}

class _LensPainter extends CustomPainter {
  _LensPainter({
    required this.frame,
    required this.dark,
    required this.borderRadius,
    this.lite = false,
  }) : super(repaint: frame);

  final LiquidFrame frame;
  final bool dark;
  final BorderRadius borderRadius;
  final bool lite;
  bool _isAttached = false;

  Size? _cachedSize;
  BorderRadius? _cachedBorderRadius;
  bool? _cachedDark;
  late Rect _rect;
  late Path _fullPath;
  Path? _ringPath;
  RRect? _vignetteRRect;
  Paint? _vignettePaint;

  final Paint _liteImagePaint = _imagePaint(1.0);
  final Paint _baseImagePaint = _imagePaint(0.55);
  final Paint _ringImagePaint = _imagePaint(0.70);

  static Paint _imagePaint(double alpha) => Paint()
    ..filterQuality = FilterQuality.low
    ..color = Colors.white.withValues(alpha: alpha);

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    if (_isAttached) return;
    _isAttached = true;
    frame.addConsumer();
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!_isAttached) return;
    _isAttached = false;
    frame.removeConsumer();
  }

  void _updateArtifacts(Size size) {
    if (_cachedSize == size &&
        _cachedBorderRadius == borderRadius &&
        _cachedDark == dark) {
      return;
    }

    _cachedSize = size;
    _cachedBorderRadius = borderRadius;
    _cachedDark = dark;
    _rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(_rect);
    _fullPath = Path()..addRRect(rrect);

    if (lite) {
      _ringPath = null;
      _vignetteRRect = null;
      _vignettePaint = null;
      return;
    }

    final inset = math.min(size.shortestSide * 0.20, 16.0);
    _ringPath = Path.combine(
      PathOperation.difference,
      _fullPath,
      Path()..addRRect(rrect.deflate(inset)),
    );
    _vignetteRRect = rrect.deflate(inset / 2);
    _vignettePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = inset
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, inset / 2)
      ..color = Colors.black.withValues(alpha: dark ? 0.10 : 0.05);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Image dibaca DI SINI (bukan saat construct) supaya selalu memegang
    // frame terkini — frame lama sudah di-dispose oleh LiquidFrame.
    final image = frame.image;
    final logical = frame.logicalSize;
    if (image == null || logical.isEmpty) return;

    _updateArtifacts(size);
    final transform = canvas.getTransform();
    final origin = Offset(transform[12], transform[13]);
    final center = origin + Offset(size.width / 2, size.height / 2);
    // Skala px image per px logis (image bisa beresolusi lebih rendah).
    final k = image.width / logical.width;

    // Blit wallpaper diperbesar [magnify] di sekitar pusat kartu; alpha
    // pada paint menggantikan saveLayer lama (image sudah flat, jadi
    // group-alpha == per-image alpha).
    void drawZone(Path clip, double magnify, Paint paint) {
      canvas.save();
      canvas.clipPath(clip);
      final src = Rect.fromCenter(
        center: Offset(center.dx * k, center.dy * k),
        width: size.width / magnify * k,
        height: size.height / magnify * k,
      );
      canvas.drawImageRect(image, src, _rect, paint);
      canvas.restore();
    }

    if (lite) {
      // Kartu: satu proyeksi penuh; tint pekat dari FtGlass yang menjaga
      // keterbacaan teks di atasnya.
      drawZone(_fullPath, 1.07, _liteImagePaint);
      return;
    }

    // Lensa dasar — seluruh bidang sedikit diperbesar.
    drawZone(_fullPath, 1.10, _baseImagePaint);

    // Cincin tepi — pembesaran kuat = background "menekuk" masuk.
    drawZone(_ringPath!, 1.35, _ringImagePaint);

    // Vignette tipis di dalam tepi — kesan ketebalan kaca.
    canvas.drawRRect(_vignetteRRect!, _vignettePaint!);
  }

  @override
  bool shouldRepaint(_LensPainter old) =>
      old.frame != frame ||
      old.dark != dark ||
      old.borderRadius != borderRadius ||
      old.lite != lite;
}

/// Touch-point illumination: kaca menyala di titik sentuh/hover dan meredup
/// saat dilepas — meniru perilaku interaktif Liquid Glass. Hanya dipakai
/// jalur chrome (nav/sheet); kartu list dilewati — Listener per kartu ikut
/// menerima tiap pointer-move saat drag-scroll dan memicu repaint kartu di
/// frekuensi input (120 Hz), penyumbang jank scroll.
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

/// Pita highlight diagonal yang menyapu permukaan (~1.6 dtk) lalu benar-
/// benar diam sampai jadwal berikutnya — controller hanya berjalan SELAMA
/// sapuan (dulu repeat() 7 dtk nonstop: 78% waktunya tick sia-sia yang
/// menahan compositor tetap bangun).
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
    duration: const Duration(milliseconds: 1600),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  void _schedule() {
    _timer = Timer(const Duration(milliseconds: 5400), () {
      if (!mounted) return;
      // Ticker bisa sedang muted (route tertutup) — forward tetap aman:
      // ia melanjutkan saat visible lagi, lalu menjadwalkan ulang.
      _ctrl.forward(from: 0).whenComplete(_schedule);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          final t = Curves.easeInOut.transform(_ctrl.value);
          return Align(
            alignment: Alignment(lerpDouble(-3.0, 3.0, t)!, 0),
            child: band,
          );
        },
      ),
    );
  }
}
