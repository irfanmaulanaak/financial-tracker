import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../household/household.dart';
import 'category_manage_helpers.dart';

class CategoryManageTile extends StatelessWidget {
  const CategoryManageTile({
    super.key,
    required this.category,
    required this.onEdit,
    required this.onArchive,
    this.archived = false,
  });
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onArchive;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: categoryManageParseColor(
              category.color,
            ).withValues(alpha: 0.15),
            child: Icon(
              categoryManageIconFor(category.icon),
              color: categoryManageParseColor(category.color),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: TextStyle(
                    color: FtColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.isInvestment
                      ? '${Money.format(category.monthlyBudget)} · Investasi'
                      : Money.format(category.monthlyBudget),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'archive') onArchive();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'archive',
                child: Text(archived ? 'Aktifkan' : 'Arsipkan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
