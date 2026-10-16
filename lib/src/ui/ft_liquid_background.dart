import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

part 'ft_liquid_frame.dart';
part 'ft_liquid_background_scene.dart';
part 'ft_liquid_background_painter.dart';

/// Background global tema Liquid: warna dasar `FtColors.bg` + blob gradient
/// aksen yang drift pelan (loop mulus 20 detik). Dipasang sekali di
/// `app.dart` di belakang Navigator; semua Scaffold transparan saat liquid
/// sehingga background ini terlihat menerus antar layar.
///
/// Model performa (Jul 2026): scene dirender SEKALI per langkah (~12 fps
/// dari loop 20 dtk) ke sebuah [ui.Image] beresolusi terbatas yang
/// dibagikan lewat [LiquidFrame]. Background DAN tiap permukaan kaca
/// (`FtGlass`/lensa) tinggal men-blit image itu — dulu tiap kartu melukis
/// ulang seluruh scene prosedural (7 shader/frame) di TIAP vsync, membuat
/// compositor tidak pernah idle di semua platform.
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
  /// Langkah baru tiap ~83 ms (~12 fps) pada loop 20 dtk. Blob super lembut
  /// bergeser ≤5 px per langkah — tak terlihat sebagai stepping. Digerakkan
  /// Timer, BUKAN Ticker/AnimationController: ticker menjadwalkan frame di
  /// TIAP vsync (60–120 Hz) dan di web/canvaskit tiap frame = re-raster
  /// seluruh scene walau tak ada yang berubah. Timer hanya membangunkan
  /// engine 12×/dtk. (Profil Chrome, lab idle: 529 → ~200 busy-sample/dtk.)
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
    _frame = LiquidFrame(onConsumersChanged: _syncTimer);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Jangan render saat app di background (hemat baterai; GPU context
    // bisa tidak tersedia di Android).
    _appVisible = state == AppLifecycleState.resumed;
    _syncTimer();
  }

  void _syncTimer() {
    final shouldRun = _animate && _appVisible && _frame.hasConsumers;
    if (shouldRun && _timer == null) {
      _timer = Timer.periodic(_stepInterval, (_) => _onStep());
    } else if (!shouldRun && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  void _onStep() {
    _t = (_clock.elapsedMilliseconds % _loopMs) / _loopMs;
    _render(notify: true);
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
    _animate = liquid && !MediaQuery.disableAnimationsOf(context);
    // Sinkron timer dengan status liquid — build ini ikut terpicu oleh
    // ftRebuildAllWidgets() saat toggle di Settings di-flip.
    _syncTimer();

    if (!liquid) {
      if (_frame.image != null) {
        _frame._set(image: null, logicalSize: Size.zero, notify: false);
      }
      return widget.child;
    }

    final size = MediaQuery.sizeOf(context);
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_frame.image == null ||
        size != _size ||
        dpr != _dpr ||
        dark != _dark) {
      _size = size;
      _dpr = dpr;
      _dark = dark;
      // Diam-diam (tanpa notify): jalur ini berjalan saat build — konsumen
      // membaca frame.image saat paint, dan perubahan MediaQuery/theme
      // sudah me-rebuild mereka. Notify hanya dari timer.
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
