import 'package:flutter/material.dart';

import '../theme.dart';
import 'ft_motion.dart';

/// Small circular check button used as the trailing action in
/// [FtSubHeader] across record-expense, record-income, add-goal,
/// edit-asset, and pay-card flows. Disabled until [enabled] is true;
/// shows a tiny progress spinner when [busy] is true.
class FtSubmitDot extends StatelessWidget {
  const FtSubmitDot({
    super.key,
    required this.busy,
    required this.enabled,
    required this.onTap,
    this.activeColor,
    this.icon = Icons.check,
  });

  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  /// Solid background when [enabled]. Defaults to ink so it matches dark
  /// action surfaces; pass [FtColors.moss] for income/positive flows.
  final Color? activeColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final active = activeColor ?? FtColors.ink;
    return FtTapScale(
      scale: 0.9,
      onTap: enabled && !busy ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: enabled ? active : FtColors.line,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FtColors.bg,
                ),
              )
            : Icon(
                icon,
                size: 18,
                color: enabled ? FtColors.bg : FtColors.ink3,
              ),
      ),
    );
  }
}
