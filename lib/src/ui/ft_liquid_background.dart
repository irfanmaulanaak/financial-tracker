import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Background global tema Liquid: neutral canvas + slow cool-color drift.
/// Dipasang sekali di belakang Navigator; semua Scaffold transparan saat
/// liquid sehingga background terlihat menerus antar layar.
///
/// Scene dirender sekitar 12 fps ke satu [ui.Image] beresolusi terbatas.
/// Background dan seluruh lensa hanya menyalin image itu; tidak ada painter
/// prosedural per-kartu atau ticker 60/120 fps.
///
/// Liquid OFF → langsung mengembalikan child (tanpa Stack, tanpa ticker).
class FtLiquidBackground extends StatefulWidget {
  const FtLiquidBackground({super.key, required this.child});

  final Widget child;

  @override
  State<FtLiquidBackground> createState() => _FtLiquidBackgroundState();
}

class _FtLiquidBackgroundState extends State<FtLiquidBackground>
    with WidgetsBindingObserver {
  static const _stepInterval = Duration(milliseconds: 83);
  static const _loopMs = 20000;

  late final LiquidFrame _frame;
  final Stopwatch _clock = Stopwatch()..start();
  Timer? _timer;
  bool _appVisible = true;
  bool _animate = false;
  double _t = 0;
  Size _size = Size.zero;
  double _dpr = 1;
  bool _dark = false;

  @override
  void initState() {
    super.initState();
    _frame = LiquidFrame(onConsumerCountChanged: _syncTimer);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appVisible = state == AppLifecycleState.resumed;
    _syncTimer();
  }

  void _syncTimer() {
    final shouldRun = _animate && _appVisible && _frame.hasConsumers;
    if (!shouldRun) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(_stepInterval, (_) {
      if (!mounted || _size.isEmpty) return;
      _t = (_clock.elapsedMilliseconds % _loopMs) / _loopMs;
      _render(notify: true);
    });
  }

  /// Render scene ke image bersama. Resolusi dibatasi ± ukuran logis dan
  /// budget piksel (blob gradient tidak punya detail halus; upscale
  /// bilinear identik — dan toImageSync di web membayar readPixels per px).
  void _render({required bool notify}) {
    if (_size.isEmpty) return;
    var scale = (_dpr * 0.5).clamp(0.5, 1.0);
    const budgetPx = 350000;
    final px = _size.width * _size.height * scale * scale;
    if (px > budgetPx) scale *= math.sqrt(budgetPx / px);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    LiquidScene.paintScene(canvas, _size, _t, _dark);
    final picture = recorder.endRecording();
    final image = picture.toImageSync(
      math.max(1, (_size.width * scale).ceil()),
      math.max(1, (_size.height * scale).ceil()),
    );
    picture.dispose();
    _frame._set(image: image, logicalSize: _size, notify: notify);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liquid = FtColors.liquid;
    if (!liquid) {
      _animate = false;
      _syncTimer();
      if (_frame.image != null) {
        _frame._set(image: null, logicalSize: Size.zero, notify: false);
      }
      return widget.child;
    }

    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (_animate != animate) {
      _animate = animate;
      _syncTimer();
    }
    if (_frame.image == null || size != _size || dpr != _dpr || dark != _dark) {
      _size = size;
      _dpr = dpr;
      _dark = dark;
      // Jalur ini berjalan saat build; perubahan MediaQuery/theme juga sudah
      // membangun ulang semua konsumen frame.
      _render(notify: false);
    }

    return LiquidScene(
      frame: _frame,
      child: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _ScenePainter(frame: _frame),
                size: Size.infinite,
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

/// Frame wallpaper bersama: image scene ter-flatten + ukuran logis yang
/// dipetakannya. Lensa yang terlihat mendaftar lewat [addConsumer], lalu
/// membaca [image] di dalam paint() supaya tidak pernah memegang image yang
/// sudah di-dispose.
class LiquidFrame extends ChangeNotifier {
  LiquidFrame({VoidCallback? onConsumerCountChanged})
    : _onConsumerCountChanged = onConsumerCountChanged;

  final VoidCallback? _onConsumerCountChanged;
  ui.Image? _image;
  Size _logicalSize = Size.zero;
  int _consumerCount = 0;

  ui.Image? get image => _image;
  bool get hasConsumers => _consumerCount > 0;

  /// Ukuran layar logis yang dipetakan [image] (resolusi image bisa lebih
  /// rendah; skala px = `image.width / logicalSize.width`).
  Size get logicalSize => _logicalSize;

  void addConsumer() {
    _consumerCount++;
    if (_consumerCount == 1) _onConsumerCountChanged?.call();
  }

  void removeConsumer() {
    if (_consumerCount == 0) {
      throw StateError('LiquidFrame consumer count cannot be negative.');
    }
    _consumerCount--;
    if (_consumerCount == 0) _onConsumerCountChanged?.call();
  }

  void _set({
    required ui.Image? image,
    required Size logicalSize,
    required bool notify,
  }) {
    _image?.dispose();
    _image = image;
    _logicalSize = logicalSize;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    _image?.dispose();
    _image = null;
    super.dispose();
  }
}

/// Scope yang membagikan [LiquidFrame] ke permukaan kaca, supaya kaca bisa
/// men-blit wallpaper identik dengan proyeksi lensa (refraksi).
class LiquidScene extends InheritedWidget {
  const LiquidScene({super.key, required this.frame, required super.child});

  final LiquidFrame frame;

  static LiquidScene? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LiquidScene>();

  /// Lukis wallpaper liquid utuh untuk layar seukuran [size] pada waktu [t].
  /// Hanya dipanggil saat me-render image bersama (sekali per langkah).
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

    // Cool spectrum only. Semantic orange/red never leaks into decoration.
    final colors = [
      FtColors.clay,
      FtColors.sky,
      FtColors.sage,
      FtColors.plum,
      FtColors.sky,
      FtColors.clay,
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
          ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r)),
      );
    }
  }

  @override
  bool updateShouldNotify(LiquidScene old) => frame != old.frame;
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

// Large, low-contrast fields create enough variation for transparent chrome
// without turning the content canvas into a decorative gradient poster.
const _specs = [
  _BlobSpec(
    cx: 0.88,
    cy: 0.05,
    r: 0.70,
    ax: 0.14,
    ay: 0.10,
    phase: 0,
    alphaLight: 0.18,
    alphaDark: 0.24,
  ),
  _BlobSpec(
    cx: 0.02,
    cy: 0.32,
    r: 0.75,
    ax: 0.12,
    ay: 0.14,
    phase: 2.1,
    alphaLight: 0.14,
    alphaDark: 0.20,
    freq: 2,
  ),
  _BlobSpec(
    cx: 0.70,
    cy: 0.92,
    r: 0.65,
    ax: 0.15,
    ay: 0.10,
    phase: 4.2,
    alphaLight: 0.13,
    alphaDark: 0.18,
  ),
  _BlobSpec(
    cx: 0.22,
    cy: -0.05,
    r: 0.55,
    ax: 0.10,
    ay: 0.09,
    phase: 1.0,
    alphaLight: 0.12,
    alphaDark: 0.17,
    freq: 2,
  ),
  _BlobSpec(
    cx: 0.12,
    cy: 0.95,
    r: 0.55,
    ax: 0.12,
    ay: 0.11,
    phase: 5.3,
    alphaLight: 0.10,
    alphaDark: 0.15,
  ),
  // Pengisi tengah — area mati antara blob pinggir tetap hidup.
  _BlobSpec(
    cx: 0.45,
    cy: 0.55,
    r: 0.50,
    ax: 0.16,
    ay: 0.13,
    phase: 3.4,
    alphaLight: 0.08,
    alphaDark: 0.12,
    freq: 1,
  ),
];

/// Blit image bersama ke layar penuh — satu drawImageRect per langkah,
/// bukan melukis ulang scene prosedural per vsync.
class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.frame}) : super(repaint: frame);

  final LiquidFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    final image = frame.image;
    if (image == null) return;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.frame != frame;
}
