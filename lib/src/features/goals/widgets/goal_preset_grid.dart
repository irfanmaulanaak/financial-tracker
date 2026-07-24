import 'package:flutter/material.dart';

import '../../../theme.dart';
import '../../../ui/ft_breakpoints.dart';

/// One preset slot in the 3×2 grid on the add-goal screen. The `tone` lookup
/// happens in [GoalPresetGrid] via [presetColor].
class GoalPreset {
  final String id;
  final String label;
  final String icon;
  final Color color;

  const GoalPreset({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

List<GoalPreset> goalPresets() => [
      GoalPreset(
        id: 'emergency',
        label: 'Dana Darurat',
        icon: 'savings',
        color: FtColors.sage,
      ),
      GoalPreset(
        id: 'vacation',
        label: 'Liburan',
        icon: 'flight',
        color: FtColors.sky,
      ),
      GoalPreset(
        id: 'house',
        label: 'Rumah',
        icon: 'home',
        color: FtColors.clay,
      ),
      GoalPreset(
        id: 'gadget',
        label: 'Gadget',
        icon: 'directions_car',
        color: FtColors.plum,
      ),
      GoalPreset(
        id: 'wedding',
        label: 'Pernikahan',
        icon: 'celebration',
        color: FtColors.plum,
      ),
      GoalPreset(
        id: 'other',
        label: 'Lainnya',
        icon: 'flag',
        color: FtColors.ochre,
      ),
    ];

/// 3×2 grid of preset goal templates. Tap fires [onSelect] with the chosen
/// preset; the active preset shows a tinted background + colored border.
class GoalPresetGrid extends StatelessWidget {
  const GoalPresetGrid({
    super.key,
    required this.presets,
    required this.activeId,
    required this.onSelect,
  });

  final List<GoalPreset> presets;
  final String? activeId;
  final ValueChanged<GoalPreset> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: context.isAtLeastMedium ? 6 : 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.05,
      children: [
        for (final p in presets)
          _PresetCell(
            preset: p,
            active: activeId == p.id,
            onTap: () => onSelect(p),
          ),
      ],
    );
  }
}

class _PresetCell extends StatelessWidget {
  const _PresetCell({
    required this.preset,
    required this.active,
    required this.onTap,
  });
  final GoalPreset preset;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: active
              ? preset.color.withValues(alpha: 0.12)
              : FtColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? preset.color : FtColors.line,
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _iconFor(preset.icon),
              size: 22,
              color: active ? preset.color : FtColors.ink2,
            ),
            const SizedBox(height: 6),
            Text(
              preset.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? FtColors.ink : FtColors.ink2,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(String name) => switch (name) {
      'savings' => Icons.savings_rounded,
      'flight' => Icons.flight_takeoff_rounded,
      'home' => Icons.home_rounded,
      'school' => Icons.school_rounded,
      'directions_car' => Icons.directions_car_rounded,
      'celebration' => Icons.celebration_rounded,
      'flag' => Icons.flag_rounded,
      _ => Icons.flag_rounded,
    };
