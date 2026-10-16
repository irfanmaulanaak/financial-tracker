part of 'ft_liquid_background.dart';

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

// "Ledger sage": SATU sumber cahaya teal-mineral dari kanan-atas (key +
// core satu keluarga hue), pantulan redup di kiri-bawah, dan SATU nada
// hangat brass sebagai penyeimbang. Tangga alpha ±2-3:1 (hero → paling
// sunyi) itulah yang membentuk kesan sumber cahaya; sebaran 5-6 hue rata
// se-roda warna justru tell gradient generatif. Tengah kanvas sengaja
// kosong — ruang negatif tempat kartu duduk dan chrome kaca mengambil
// sampel warna yang stabil (wash bgAlt sudah mencegah flat). Drift ≤0.05
// supaya scene bergerak sebagai satu atmosfer, bukan orb lepas.
//
// Hue teal/brass SENGAJA di luar token aksen FtColors (sage/moss/ochre):
// palet aksen diturunkan dari claude-design/theme.jsx dan kertas cream-nya
// ±identik ivory Anthropic, jadi wallpaper yang memakai token itu langsung
// terbaca "palet Claude". Teal-mineral aman ganda: bukan tetangga dekat
// aksen dormant Anthropic mana pun (ΔE ≥ ~23), dan pada alpha wallpaper
// tak menabrak makna semantik hijau/merah (healthOk/danger) di chip.
const _specs = [
  // Key light — pusat di luar kanvas, terbesar dan paling kuat.
  _BlobSpec(
      cx: 0.86, cy: -0.12, r: 0.90, ax: 0.045, ay: 0.035,
      phase: 0,
      light: Color(0xFF648C88), dark: Color(0xFF335D57),
      alphaLight: 0.15, alphaDark: 0.13),
  // Core — bersarang DI DALAM key: satu hot spot berdimensi, bukan dua
  // lingkaran terpisah. Dark lebih dalam, bukan lebih terang.
  _BlobSpec(
      cx: 0.98, cy: 0.14, r: 0.50, ax: 0.030, ay: 0.040,
      phase: 1.6,
      light: Color(0xFF28584F), dark: Color(0xFF20463F),
      alphaLight: 0.09, alphaDark: 0.08, freq: 2),
  // Bounce — pantulan redup satu keluarga dengan key, seberang diagonal.
  _BlobSpec(
      cx: 0.28, cy: 1.06, r: 0.72, ax: 0.040, ay: 0.045,
      phase: 3.2,
      light: Color(0xFF4C7166), dark: Color(0xFF2F5048),
      alphaLight: 0.08, alphaDark: 0.10),
  // Nada hangat — satu-satunya warna hangat (brass tua), muncul sekali
  // sebagai penyeimbang; bukan ochre token supaya tak menyeret balik
  // asosiasi parchment/emas Claude.
  _BlobSpec(
      cx: -0.06, cy: 0.60, r: 0.82, ax: 0.035, ay: 0.030,
      phase: 4.8,
      light: Color(0xFFA98222), dark: Color(0xFF665014),
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
