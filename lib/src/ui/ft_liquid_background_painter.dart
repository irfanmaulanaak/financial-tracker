part of 'ft_liquid_background.dart';

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
