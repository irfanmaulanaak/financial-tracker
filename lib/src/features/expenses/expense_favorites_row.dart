import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../household/household.dart';

import 'favorite_expenses.dart';

/// Deretan chip favorit di atas form catat. Tap → isi form; long-press →
/// hapus. Tidak dirender saat kosong.
class ExpenseFavoritesRow extends ConsumerWidget {
  const ExpenseFavoritesRow({
    super.key,
    required this.categories,
    required this.onPick,
  });

  final List<Category> categories;
  final ValueChanged<FavoriteExpense> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoriteExpensesProvider);
    final activeIds = {for (final c in categories) c.id};
    final usable =
        [for (final f in favorites) if (activeIds.contains(f.categoryId)) f];
    if (usable.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Favorit'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in usable)
              GestureDetector(
                onLongPress: () {
                  FtHaptics.warning();
                  ref.read(favoriteExpensesProvider.notifier).remove(f);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Favorit "${f.note}" dihapus.')),
                  );
                },
                child: ActionChip(
                  onPressed: () {
                    FtHaptics.select();
                    onPick(f);
                  },
                  backgroundColor: FtColors.surface,
                  side: BorderSide(color: FtColors.line, width: 0.5),
                  label: Text(
                    '${f.note} · ${Money.compact(f.amount)}',
                    style: TextStyle(fontSize: 12, color: FtColors.ink),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
