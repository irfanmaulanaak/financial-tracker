import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';

const _idMonthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String dueLabelFromMonths(int monthsTo) {
  final due = DateTime(DateTime.now().year, DateTime.now().month + monthsTo);
  return '${_idMonthsShort[due.month - 1]} ${due.year}';
}

IconData goalIconFor(String name) => switch (name) {
      'savings' => Icons.savings_rounded,
      'flight' => Icons.flight_takeoff_rounded,
      'home' => Icons.home_rounded,
      'school' => Icons.school_rounded,
      'directions_car' => Icons.directions_car_rounded,
      'celebration' => Icons.celebration_rounded,
      'flag' => Icons.flag_rounded,
      _ => Icons.flag_rounded,
    };

/// Top "preview" hero on the add-goal screen: icon badge, name, projection,
/// and a thin progress bar when a target has been set.
class GoalPreviewHero extends StatelessWidget {
  const GoalPreviewHero({
    super.key,
    required this.icon,
    required this.label,
    required this.tone,
    required this.target,
    required this.current,
    required this.monthly,
    required this.monthsTo,
  });
  final String icon;
  final String label;
  final Color tone;
  final int target;
  final int current;
  final int monthly;
  final int monthsTo;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: tone.withValues(alpha: 0.32), width: 0.5),
            ),
            child: Icon(goalIconFor(icon), size: 26, color: tone),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.isEmpty ? 'Tujuan Baru' : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  target > 0
                      ? '${Money.format(monthly)}/bln · ${dueLabelFromMonths(monthsTo)}'
                      : 'Atur target untuk melihat proyeksi',
                  style: TextStyle(color: FtColors.ink3, fontSize: 11),
                ),
                if (target > 0) ...[
                  const SizedBox(height: 8),
                  FtProgressBar(
                    value: current,
                    max: target == 0 ? 1 : target,
                    color: tone,
                    height: 3,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GoalToneRow extends StatelessWidget {
  const GoalToneRow({
    super.key,
    required this.tone,
    required this.onChange,
  });
  final Color tone;
  final ValueChanged<Color> onChange;

  static final _tones = [
    FtColors.clay,
    FtColors.sage,
    FtColors.sky,
    FtColors.plum,
    FtColors.ochre,
    FtColors.moss,
    FtColors.blush,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final c in _tones) ...[
          GestureDetector(
            onTap: () => onChange(c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: tone == c ? FtColors.ink : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class GoalMonthsRow extends StatelessWidget {
  const GoalMonthsRow({
    super.key,
    required this.monthsTo,
    required this.monthsList,
    required this.onChange,
  });
  final int monthsTo;
  final List<int> monthsList;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Eyebrow('Tercapai dalam')),
            Text(
              dueLabelFromMonths(monthsTo),
              style: TextStyle(color: FtColors.ink3, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final m in monthsList) ...[
                _Chip(
                  label: m < 12
                      ? '$m bulan'
                      : (m == 12 ? '1 tahun' : '${m ~/ 12} tahun'),
                  active: m == monthsTo,
                  onTap: () => onChange(m),
                ),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.95,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? FtColors.ink : FtColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? FtColors.ink : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? FtColors.bg : FtColors.ink2,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class GoalProjectionCard extends StatelessWidget {
  const GoalProjectionCard({
    super.key,
    required this.tone,
    required this.monthly,
    required this.monthsTo,
    required this.current,
  });
  final Color tone;
  final int monthly;
  final int monthsTo;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: tone.withValues(alpha: 0.28), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 14, color: tone),
              const SizedBox(width: 6),
              const Eyebrow('Proyeksi'),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 13,
                fontFamily: 'Newsreader',
                height: 1.45,
              ),
              children: [
                const TextSpan(text: 'Menabung '),
                TextSpan(
                  text: Money.format(monthly),
                  style: TextStyle(
                      color: tone, fontWeight: FontWeight.w500),
                ),
                const TextSpan(text: ' per bulan'),
                if (current > 0) ...[
                  const TextSpan(text: ' dari saldo awal '),
                  TextSpan(
                    text: Money.format(current),
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
                const TextSpan(text: ', tujuan tercapai dalam '),
                TextSpan(
                  text: '$monthsTo bulan',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

