import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme.dart';
import '../../ui/ft_refresh.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/household_repository.dart';
import 'widgets/category_manage_edit_sheet.dart';
import 'widgets/category_manage_tile.dart';

export 'widgets/category_manage_edit_sheet.dart';
export 'widgets/category_manage_helpers.dart';
export 'widgets/category_manage_tile.dart';

class CategoryManageScreen extends ConsumerWidget {
  const CategoryManageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final active = household.categories.where((c) => !c.archived).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final archived = household.categories.where((c) => c.archived).toList();

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: FtRefreshable(
        onRefresh: () async {
          ref.invalidate(currentHouseholdProvider);
          await ftRefreshDelay();
        },
        child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          FtSubHeader(
            title: 'Kategori',
            trailing: FtAddButton(
              tooltip: 'Tambah kategori',
              onTap: () => _openAddSheet(context, ref, household),
            ),
          ),
          const FtSectionHeader(title: 'Aktif'),
          for (final c in active)
            CategoryManageTile(
              category: c,
              onEdit: () => _openEditSheet(context, ref, household, c),
              onArchive: () => _archive(context, ref, household, c, true),
            ),
          if (archived.isNotEmpty) ...[
            const FtSectionHeader(title: 'Arsip'),
            for (final c in archived)
              CategoryManageTile(
                category: c,
                archived: true,
                onEdit: () => _openEditSheet(context, ref, household, c),
                onArchive: () => _archive(context, ref, household, c, false),
              ),
          ],
        ],
      ),
      ),
    );
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    Household h,
    Category c,
    bool archived,
  ) async {
    final updated = h.categories
        .map((x) => x.id == c.id ? x.copyWith(archived: archived) : x)
        .toList();
    try {
      await ref
          .read(householdRepositoryProvider)
          .updateCategories(householdId: h.id, categories: updated);
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal mengubah kategori');
      }
    }
  }

  Future<void> _openAddSheet(
    BuildContext context,
    WidgetRef ref,
    Household h,
  ) async {
    final saved = await showModalBottomSheet<CategoryDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const CategoryEditSheet(),
    );
    if (saved == null) return;
    try {
      await ref
          .read(householdRepositoryProvider)
          .addCategory(
            householdId: h.id,
            label: saved.label,
            icon: saved.icon,
            color: saved.color,
            monthlyBudget: saved.budget,
            isInvestment: saved.isInvestment,
            ziswaf: saved.ziswaf,
          );
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menambah kategori');
      }
    }
  }

  Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    Household h,
    Category c,
  ) async {
    final saved = await showModalBottomSheet<CategoryDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryEditSheet(initial: c),
    );
    if (saved == null) return;
    final updated = h.categories
        .map(
          (x) => x.id == c.id
              ? x.copyWith(
                  label: saved.label,
                  icon: saved.icon,
                  color: saved.color,
                  monthlyBudget: saved.budget,
                  isInvestment: saved.isInvestment,
                  ziswaf: saved.ziswaf,
                )
              : x,
        )
        .toList();
    try {
      await ref
          .read(householdRepositoryProvider)
          .updateCategories(householdId: h.id, categories: updated);
    } catch (e) {
      if (context.mounted) {
        showFtErrorSnack(context, e, prefix: 'Gagal menyimpan kategori');
      }
    }
  }
}
