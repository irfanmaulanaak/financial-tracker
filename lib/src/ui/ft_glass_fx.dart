import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'ft_liquid_background.dart';

/// Lapisan "lensing" — inti tampilan Liquid Glass.
///
/// Wallpaper liquid sudah dirender sekali per langkah (~12 fps) ke image
/// bersama di [LiquidFrame], jadi kaca tinggal men-blit image itu dengan
/// dua proyeksi (drawImageRect — murah, tanpa shader/saveLayer per frame):
/// - seluruh bidang diperbesar ~1.10 (lensa dasar), dan
/// - cincin tepi diperbesar ~1.35 → background tampak membelok ke dalam di
///   tepi, persis perilaku lensa cembung (tengah datar, tepi menekuk kuat).
class GlassLensLayer extends StatefulWidget {
  const GlassLensLayer({super.key, required this.borderRadius});

  final BorderRadius borderRadius;

  @override
  State<GlassLensLayer> createState() => _GlassLensLayerState();
}

class _GlassLensLayerState extends State<GlassLensLayer> {
  LiquidFrame? _frame;
  bool _registered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final frame = LiquidScene.maybeOf(context)?.frame;
    final shouldRegister =
        frame != null && TickerMode.valuesOf(context).enabled;
    if (_frame == frame && _registered == shouldRegister) return;

    if (_registered) _frame!.removeConsumer();
    _frame = frame;
    _registered = shouldRegister;
    if (_registered) _frame!.addConsumer();
  }

  @override
  void dispose() {
    if (_registered) _frame!.removeConsumer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    if (frame == null) return const SizedBox.shrink();

    final dark = Theme.of(context).brightness == Brightness.dark;
    return IgnorePointer(
      child: CustomPaint(
        painter: _LensPainter(
          frame: frame,
          dark: dark,
          borderRadius: widget.borderRadius,
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
  }) : super(repaint: frame) {
    _basePaint = Paint()
      ..filterQuality = FilterQuality.low
      ..color = Colors.white.withValues(alpha: 0.24);
    _ringPaint = Paint()
      ..filterQuality = FilterQuality.low
      ..color = Colors.white.withValues(alpha: 0.34);
    _vignettePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black.withValues(alpha: dark ? 0.07 : 0.035);
  }

  final LiquidFrame frame;
  final bool dark;
  final BorderRadius borderRadius;

  late final Paint _basePaint;
  late final Paint _ringPaint;
  late final Paint _vignettePaint;
  Size _cachedSize = Size.zero;
  Rect _rect = Rect.zero;
  late Path _baseClip;
  late Path _ringClip;
  late RRect _vignette;

  void _updateGeometry(Size size) {
    if (_cachedSize == size) return;
    _cachedSize = size;
    _rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(_rect);
    final inset = math.min(size.shortestSide * 0.20, 16.0);
    _baseClip = Path()..addRRect(rrect);
    _ringClip = Path.combine(
      PathOperation.difference,
      _baseClip,
      Path()..addRRect(rrect.deflate(inset)),
    );
    _vignette = rrect.deflate(inset / 2);
    _vignettePaint
      ..strokeWidth = inset
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, inset / 2);
  }

  void _drawZone(
    Canvas canvas,
    ui.Image image,
    Offset center,
    double scale,
    Path clip,
    double magnify,
    Paint paint,
  ) {
    canvas.save();
    canvas.clipPath(clip);
    final src = Rect.fromCenter(
      center: Offset(center.dx * scale, center.dy * scale),
      width: _cachedSize.width / magnify * scale,
      height: _cachedSize.height / magnify * scale,
    );
    canvas.drawImageRect(image, src, _rect, paint);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Image dibaca DI SINI (bukan saat construct) supaya selalu memegang
    // frame terkini — frame lama sudah di-dispose oleh LiquidFrame.
    final image = frame.image;
    final logical = frame.logicalSize;
    if (image == null || logical.isEmpty || size.isEmpty) return;

    _updateGeometry(size);
    final transform = canvas.getTransform();
    final origin = Offset(transform[12], transform[13]);
    final center = origin + Offset(size.width / 2, size.height / 2);
    // Skala px image per px logis (image bisa beresolusi lebih rendah).
    final k = image.width / logical.width;

    // Lensa dasar — seluruh bidang sedikit diperbesar.
    _drawZone(canvas, image, center, k, _baseClip, 1.08, _basePaint);
    // Cincin tepi — pembesaran kuat membuat background menekuk masuk.
    _drawZone(canvas, image, center, k, _ringClip, 1.24, _ringPaint);

    // Vignette tipis di dalam tepi — kesan ketebalan kaca.
    canvas.drawRRect(_vignette, _vignettePaint);
  }

  @override
  bool shouldRepaint(_LensPainter old) =>
      old.frame != frame ||
      old.dark != dark ||
      old.borderRadius != borderRadius;
}
