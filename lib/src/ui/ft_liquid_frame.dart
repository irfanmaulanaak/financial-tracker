part of 'ft_liquid_background.dart';

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

    // Cast kertas, KHUSUS liquid (fungsi ini tak berjalan saat OFF, mode
    // non-liquid tetap pixel-identik): bg ±identik dengan ivory Anthropic
    // (ΔE00 <1) sehingga kertasnya sendiri terbaca "palet Claude". Cast
    // teal menggeser persepsi kertas ~ΔE00 2 — terlihat pada bidang penuh,
    // tak terasa per piksel; kontras ink di atasnya tetap ≥14:1.
    canvas.drawRect(
      rect,
      Paint()
        ..color = dark
            ? const Color(0xFF31594F).withValues(alpha: 0.08)
            : const Color(0xFF3F6662).withValues(alpha: 0.06),
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
