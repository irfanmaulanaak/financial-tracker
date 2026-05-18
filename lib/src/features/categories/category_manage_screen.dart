import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../household/household_repository.dart';

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
            _CategoryTile(
              category: c,
              onEdit: () => _openEditSheet(context, ref, household, c),
              onArchive: () => _archive(context, ref, household, c, true),
            ),
          if (archived.isNotEmpty) ...[
            const FtSectionHeader(title: 'Arsip'),
            for (final c in archived)
              _CategoryTile(
                category: c,
                archived: true,
                onEdit: () => _openEditSheet(context, ref, household, c),
                onArchive: () => _archive(context, ref, household, c, false),
              ),
          ],
        ],
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
    final saved = await showModalBottomSheet<_CategoryDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CategoryEditSheet(),
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
    final saved = await showModalBottomSheet<_CategoryDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CategoryEditSheet(initial: c),
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
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
            backgroundColor: _parseColor(
              category.color,
            ).withValues(alpha: 0.15),
            child: Icon(
              _iconFor(category.icon),
              color: _parseColor(category.color),
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
                  Money.format(category.monthlyBudget),
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

class _CategoryDraft {
  final String label;
  final String icon;
  final String color;
  final int budget;
  const _CategoryDraft(this.label, this.icon, this.color, this.budget);
}

class _CategoryEditSheet extends StatefulWidget {
  const _CategoryEditSheet({this.initial});
  final Category? initial;

  @override
  State<_CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<_CategoryEditSheet> {
  late final TextEditingController _label = TextEditingController(
    text: widget.initial?.label ?? '',
  );
  late final TextEditingController _budget = TextEditingController(
    text: widget.initial != null
        ? Money.displayDigits(widget.initial!.monthlyBudget)
        : '',
  );
  String _color = '#3B82F6';
  String _icon = 'category';

  static const _iconChoices = [
    'restaurant',
    'receipt_long',
    'shopping_bag',
    'directions_car',
    'movie',
    'favorite',
    'category',
    'school',
    'pets',
    'sports_esports',
  ];
  static const _colorChoices = [
    '#F59E0B',
    '#3B82F6',
    '#EC4899',
    '#10B981',
    '#8B5CF6',
    '#EF4444',
    '#64748B',
    '#0EA5E9',
  ];

  @override
  void initState() {
    super.initState();
    _icon = widget.initial?.icon ?? _icon;
    _color = widget.initial?.color ?? _color;
  }

  @override
  void dispose() {
    _label.dispose();
    _budget.dispose();
    super.dispose();
  }

  void _save() {
    final label = _label.text.trim();
    if (label.isEmpty) return;
    final budget = Money.parse(_budget.text) ?? 0;
    Navigator.pop(context, _CategoryDraft(label, _icon, _color, budget));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.initial == null ? 'Kategori baru' : 'Edit kategori',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nama kategori'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _budget,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                ThousandsSeparatorFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Budget bulanan',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            const Text('Ikon'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final i in _iconChoices)
                  GestureDetector(
                    onTap: () => setState(() => _icon = i),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _icon == i
                            ? _parseColor(_color).withValues(alpha: 0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: _icon == i
                            ? Border.all(color: _parseColor(_color))
                            : null,
                      ),
                      child: Icon(_iconFor(i)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Warna'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final c in _colorChoices)
                  GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _parseColor(c),
                        shape: BoxShape.circle,
                        border: _color == c
                            ? Border.all(width: 3, color: Colors.black)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Simpan')),
          ],
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}

IconData _iconFor(String name) => switch (name) {
  'restaurant' => Icons.restaurant,
  'receipt_long' => Icons.receipt_long,
  'shopping_bag' => Icons.shopping_bag,
  'directions_car' => Icons.directions_car,
  'movie' => Icons.movie,
  'favorite' => Icons.favorite,
  'school' => Icons.school,
  'pets' => Icons.pets,
  'sports_esports' => Icons.sports_esports,
  _ => Icons.category,
};
