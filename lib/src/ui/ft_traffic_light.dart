import 'package:flutter/material.dart';

import '../theme.dart';

enum FtHealthState { good, caution, risk }

/// Three-circle traffic light used on the health detector + category verdict
/// boxes. Active circle glows; inactive circles dim.
class FtTrafficLight extends StatelessWidget {
  const FtTrafficLight({
    super.key,
    required this.state,
    this.vertical = false,
    this.size = 18,
  });

  final FtHealthState state;
  final bool vertical;
  final double size;

  @override
  Widget build(BuildContext context) {
    final lights = <Widget>[
      _light(FtColors.healthOk, state == FtHealthState.good),
      _light(FtColors.healthWarn, state == FtHealthState.caution),
      _light(FtColors.healthBad, state == FtHealthState.risk),
    ];
    final children = <Widget>[];
    for (var i = 0; i < lights.length; i++) {
      children.add(lights[i]);
      if (i != lights.length - 1) {
        children.add(
          SizedBox(width: vertical ? 0 : 6, height: vertical ? 6 : 0),
        );
      }
    }
    return vertical
        ? Column(mainAxisSize: MainAxisSize.min, children: children)
        : Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  Widget _light(Color color, bool active) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: active ? color : color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.55),
                  blurRadius: 5,
                  spreadRadius: 0.5,
                ),
              ]
            : null,
      ),
    );
  }
}
