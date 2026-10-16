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
            iconKey: c.icon,
            // The seeded "Lainnya" category (id 'other') legitimately uses
            // the generic icon; any other category stuck on it just never
            // had one picked.
            iconChosen: c.icon != 'category' || c.id == 'other',
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
    required this.iconKey,
    required this.iconChosen,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String iconKey;
  final bool iconChosen;
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
    'pets': Icons.pets,
    'sports_esports': Icons.sports_esports,
    'trending_up': Icons.trending_up,
  };

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : FtColors.ink3;
    return FtTapScale(
      scale: 0.95,
      haptic: false,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? FtColors.clay : FtColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? FtColors.clay : FtColors.line,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // No icon picked: a quiet neutral dot instead of reusing the
            // "Lainnya" catch-all icon, so custom categories don't all look
            // like the same bucket.
            if (iconChosen)
              Icon(_icons[iconKey] ?? Icons.category, size: 12, color: iconColor)
            else
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
              ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : FtColors.ink2,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
