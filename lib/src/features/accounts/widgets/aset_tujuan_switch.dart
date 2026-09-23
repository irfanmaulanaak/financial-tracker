import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../theme.dart';
import '../../../ui/ft_haptics.dart';
import '../../../ui/ft_motion.dart';

/// Aset | Tujuan switch under the Aset tab title. Tujuan has no bottom-nav
/// slot of its own; it lives behind the Aset tab (goals can be funded by
/// assets, so the two belong together).
class AsetTujuanSwitch extends StatelessWidget {
  const AsetTujuanSwitch({super.key, required this.goalsActive});

  final bool goalsActive;

  @override
  Widget build(BuildContext context) {
    Widget segment(String label, bool active, String path) => Expanded(
          child: Semantics(
            button: true,
            selected: active,
            child: FtTapScale(
              scale: 0.97,
              haptic: false,
              onTap: active
                  ? null
                  : () {
                      FtHaptics.select();
                      context.go(path);
                    },
              child: SizedBox(
                height: 40,
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: active ? FtColors.ink : FtColors.ink3,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    // Aset and Tujuan are separate routes, so the thumb slides in from the
    // side you came from when the new screen mounts.
    final to = goalsActive ? 1.0 : -1.0;
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 14),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: FtColors.bgAlt,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: -to, end: to),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 340),
              curve: Curves.easeOutCubic,
              builder: (context, x, _) => Align(
                alignment: Alignment(x, 0),
                child: FractionallySizedBox(
                  widthFactor: 0.5,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: FtColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              segment('Aset', !goalsActive, '/accounts'),
              segment('Tujuan', goalsActive, '/goals'),
            ],
          ),
        ],
      ),
    );
  }
}
