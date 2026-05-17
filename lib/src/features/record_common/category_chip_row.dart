import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../ui/ft_motion.dart';
import '../household/household.dart';

/// Wrapped row of category chips for the record-expense flow. The currently
/// selected chip fills with its own color; unselected chips show an outlined
/// surface with the icon tinted to the category color.
class CategoryChipRow extends StatelessWidget {
  const CategoryChipRow({
    super.key,
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<Category> categories;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in categories)
          _Chip(
            label: c.label.split(' ').first,
            color: Color(
              int.parse('FF${c.color.replaceFirst('#', '')}', radix: 16),
            ),
            iconKey: c.icon,
            selected: selected == c.id,
            onTap: () => onSelect(c.id),
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.color,
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  static final _icons = <String, IconData>{
    'restaurant': Icons.restaurant,
    'receipt_long': Icons.receipt_long,
    'shopping_bag': Icons.shopping_bag,
    'directions_car': Icons.directions_car,
    'movie': Icons.movie,
    'favorite': Icons.favorite,
    'school': Icons.school,
    'sports_esports': Icons.sports_esports,
  };

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.95,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color : FtColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icons[iconKey] ?? Icons.category,
              size: 13,
              color: selected ? Colors.white : color,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : FtColors.ink2,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
