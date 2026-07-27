import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme.dart';

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

/// Frame wallpaper bersama: image scene ter-flatten + ukuran logis yang
/// dipetakannya. Konsumen mendaftar sebagai `repaint:` listener pada
/// CustomPainter dan MEMBACA [image] di dalam paint() (bukan menangkapnya
/// saat build) supaya tidak pernah memegang image yang sudah di-dispose.
class LiquidFrame extends ChangeNotifier {
  LiquidFrame({VoidCallback? onConsumersChanged})
    : _onConsumersChanged = onConsumersChanged;

  final VoidCallback? _onConsumersChanged;
  ui.Image? _image;
  Size _logicalSize = Size.zero;
  int _consumerCount = 0;

  ui.Image? get image => _image;
  bool get hasConsumers => _consumerCount > 0;

  /// Ukuran layar logis yang dipetakan [image] (resolusi image bisa lebih
  /// rendah; skala px = `image.width / logicalSize.width`).
  Size get logicalSize => _logicalSize;

  void addConsumer() {
    _consumerCount += 1;
    if (_consumerCount == 1) _onConsumersChanged?.call();
  }

  void removeConsumer() {
    assert(_consumerCount > 0);
    _consumerCount -= 1;
    if (_consumerCount == 0) _onConsumersChanged?.call();
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
  const LiquidScene({
    super.key,
    required this.frame,
    required super.child,
  });

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

    const twoPi = 2 * math.pi;
    for (final b in _specs) {
      final cx =
          (b.cx + b.ax * math.sin(twoPi * b.freq * t + b.phase)) * size.width;
      final cy =
          (b.cy + b.ay * math.cos(twoPi * b.freq * t + b.phase)) * size.height;
      final r = size.shortestSide * b.r;
      final base = dark ? b.dark : b.light;
      final a = dark ? b.alphaDark : b.alphaLight;
      canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          // Falloff cekung piecewise (aproksimasi inverse-square) — ramp
          // linear tunggal membuat blob terbaca sebagai piringan bertepi.
          ..shader = RadialGradient(
            colors: [
              base.withValues(alpha: a),
              base.withValues(alpha: a * 0.50),
              base.withValues(alpha: a * 0.16),
              base.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.45, 0.75, 1.0],
          ).createShader(
            Rect.fromCircle(center: Offset(cx, cy), radius: r),
          ),
      );
    }

    // Grain monokrom ±2%: memecah banding pada blur besar (banding sendiri
    // adalah tell gradient generatif). Murah — ter-bake ke image bersama.
    canvas.drawRect(rect, Paint()..shader = _grainShader());
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
    required this.light,
    required this.dark,
    required this.alphaLight,
    required this.alphaDark,
    this.freq = 1,
  });

  final double cx, cy; // pusat (fraksi lebar/tinggi)
  final double r; // radius (fraksi sisi terpendek)
  final double ax, ay; // amplitudo drift (fraksi)
  final double phase;
  final Color light, dark; // warna blob per mode (dark: lebih dalam, BUKAN
  // lebih terang — varian dark di-author terpisah ala wallpaper iOS 26)
  final double alphaLight, alphaDark;
  final double freq; // siklus per loop — bilangan bulat agar loop mulus
}

// "Paper under warm light": SATU sumber cahaya hangat dari kanan-atas
// (key + core keluarga clay/ochre, busur hue ±55°), pantulan lemah di
// kiri-bawah, dan SATU nada dingin sebagai bayangan. Tangga alpha ±3:1
// (hero → paling sunyi) itulah yang membentuk kesan sumber cahaya; sebaran
// 5-6 hue rata se-roda warna justru tell gradient generatif. Tengah kanvas
// sengaja kosong — ruang negatif tempat kartu duduk dan chrome kaca
// mengambil sampel warna yang stabil (wash bgAlt sudah mencegah flat).
// Drift ≤0.05 supaya scene bergerak sebagai satu atmosfer, bukan orb lepas.
const _specs = [
  // Key light — pusat di luar kanvas, terbesar dan paling kuat.
  _BlobSpec(
      cx: 0.86, cy: -0.12, r: 0.90, ax: 0.045, ay: 0.035,
      phase: 0,
      light: Color(0xFFE9B872), dark: Color(0xFFC98A3E),
      alphaLight: 0.20, alphaDark: 0.17),
  // Core clay — bersarang DI DALAM key: satu hot spot berdimensi,
  // bukan dua lingkaran terpisah. Varian dark memakai clay bara yang lebih
  // dalam (bukan token aksen dark yang justru lebih terang) supaya overlap
  // key+core tidak menghasilkan patch oranye panas.
  _BlobSpec(
      cx: 0.98, cy: 0.14, r: 0.50, ax: 0.030, ay: 0.040,
      phase: 1.6,
      light: Color(0xFFC4612A), dark: Color(0xFFB05A28),
      alphaLight: 0.12, alphaDark: 0.08, freq: 2),
  // Bounce hangat — pantulan redup di seberang diagonal.
  _BlobSpec(
      cx: 0.28, cy: 1.06, r: 0.72, ax: 0.040, ay: 0.045,
      phase: 3.2,
      light: Color(0xFFD98E5A), dark: Color(0xFF8A5A3C),
      alphaLight: 0.09, alphaDark: 0.11),
  // Bayangan — satu-satunya nada dingin (sage keabu-abuan), muncul sekali.
  _BlobSpec(
      cx: -0.06, cy: 0.60, r: 0.82, ax: 0.035, ay: 0.030,
      phase: 4.8,
      light: Color(0xFF78877E), dark: Color(0xFF3E5A55),
      alphaLight: 0.07, alphaDark: 0.09),
];

/// Shader grain di-cache (image + matrix tak pernah berubah) — membuat
/// ImageShader baru tiap langkah = ~720 objek native/menit menunggu GC.
ui.ImageShader _grainShader() {
  return _grainShaderCached ??= ui.ImageShader(
    _grainTile(),
    ui.TileMode.repeated,
    ui.TileMode.repeated,
    Matrix4.identity().storage,
  );
}

ui.ImageShader? _grainShaderCached;

/// Tile noise 64×64 (dither hitam/putih ±2% alpha), dibuat sekali secara
/// deterministik lalu di-tile lewat [_grainShader] saat scene di-render.
ui.Image _grainTile() {
  final cached = _grain;
  if (cached != null) return cached;
  const side = 64;
  final rand = math.Random(7);
  final white = <Offset>[];
  final black = <Offset>[];
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      (rand.nextBool() ? white : black).add(Offset(x + 0.5, y + 0.5));
    }
  }
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  void dots(List<Offset> pts, Color color) {
    canvas.drawPoints(
      ui.PointMode.points,
      pts,
      Paint()
        ..color = color
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.square,
    );
  }

  dots(white, const Color(0x05FFFFFF));
  dots(black, const Color(0x05000000));
  final picture = recorder.endRecording();
  final image = picture.toImageSync(side, side);
  picture.dispose();
  return _grain = image;
}

ui.Image? _grain; // 16 KB, hidup selama app — sengaja tak pernah di-dispose.

/// Blit image bersama ke layar penuh — satu drawImageRect per langkah,
/// bukan melukis ulang scene prosedural per vsync.
class _ScenePainter extends CustomPainter {
  _ScenePainter({required this.frame}) : super(repaint: frame);

  final LiquidFrame frame;
  bool _isAttached = false;

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
