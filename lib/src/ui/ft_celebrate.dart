import 'package:flutter/material.dart';

import '../theme.dart';
import 'ft_haptics.dart';

/// Briefly overlays a checkmark badge over the current screen — used after a
/// successful save (expense recorded, goal contribution, transfer). Fires a
/// success haptic on entry. Auto-dismisses after ~700 ms.
class FtCelebrate {
  FtCelebrate._();

  static void show(
    BuildContext context, {
    String? message,
    Duration hold = const Duration(milliseconds: 600),
  }) {
    FtHaptics.success();
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _FtCelebrateOverlay(
        message: message,
        hold: hold,
        onDone: () {
          entry.remove();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _FtCelebrateOverlay extends StatefulWidget {
  const _FtCelebrateOverlay({
    required this.hold,
    required this.onDone,
    this.message,
  });

  final Duration hold;
  final VoidCallback onDone;
  final String? message;

  @override
  State<_FtCelebrateOverlay> createState() => _FtCelebrateOverlayState();
}

class _FtCelebrateOverlayState extends State<_FtCelebrateOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _scale = CurvedAnimation(
      parent: _ctrl,
      curve: const Cubic(0.34, 1.56, 0.64, 1),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _run();
  }

  Future<void> _run() async {
    await _ctrl.forward();
    await Future<void>.delayed(widget.hold);
    if (!mounted) return;
    await _ctrl.reverse();
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(_scale),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 22, vertical: 18),
              decoration: BoxDecoration(
                color: FtColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: FtColors.line, width: 0.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1F000000),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: FtColors.moss.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: FtColors.moss.withValues(alpha: 0.24),
                        width: 0.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check_rounded,
                      color: FtColors.moss,
                      size: 26,
                    ),
                  ),
                  if (widget.message != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      widget.message!,
                      style: TextStyle(
                        color: FtColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
