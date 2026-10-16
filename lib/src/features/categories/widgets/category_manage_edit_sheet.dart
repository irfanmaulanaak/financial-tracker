import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters.dart';
import '../../household/household.dart';
import 'category_manage_helpers.dart';

class CategoryDraft {
  final String label;
  final String icon;
  final String color;
  final int budget;
  final bool isInvestment;
  final bool ziswaf;
  const CategoryDraft(
    this.label,
    this.icon,
    this.color,
    this.budget,
    this.isInvestment,
    this.ziswaf,
  );
}

class CategoryEditSheet extends StatefulWidget {
  const CategoryEditSheet({super.key, this.initial});
  final Category? initial;

  @override
  State<CategoryEditSheet> createState() => _CategoryEditSheetState();
}

class _CategoryEditSheetState extends State<CategoryEditSheet> {
  late final TextEditingController _label = TextEditingController(
    text: widget.initial?.label ?? '',
  );
  late final TextEditingController _budget = TextEditingController(
    text: widget.initial != null
        ? Money.displayDigits(widget.initial!.monthlyBudget)
        : '',
  );
  String _color = '#5E7A64';
  String _icon = 'category';
  late bool _isInvestment = widget.initial?.isInvestment ?? false;
  late bool _ziswaf = widget.initial?.ziswaf ?? false;

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
    'trending_up',
  ];
  // Editorial palette (light values of `FtColors.cat*` + blush); parseColor
  // maps them to dark variants automatically.
  static const _colorChoices = [
    '#C4612A',
    '#B89030',
    '#7A3F4E',
    '#5E7A64',
    '#3A6075',
    '#2D5040',
    '#A89880',
    '#E8B4C0',
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
    Navigator.pop(
      context,
      CategoryDraft(label, _icon, _color, budget, _isInvestment, _ziswaf),
    );
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
            const SizedBox(height: 4),
            SwitchListTile(
              value: _isInvestment,
              onChanged: (v) => setState(() => _isInvestment = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Kategori investasi'),
              subtitle: const Text(
                'Tetap tampil di daftar, tapi tidak dihitung '
                'dalam total pengeluaran',
                style: TextStyle(fontSize: 12),
              ),
            ),
            SwitchListTile(
              value: _ziswaf,
              onChanged: (v) => setState(() => _ziswaf = v),
              contentPadding: EdgeInsets.zero,
              title: const Text('Kategori ZISWAF'),
              subtitle: const Text(
                'Zakat, infak, sedekah, wakaf. Total tahunannya '
                'direkap di layar Rekap Siklus',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
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
                            ? categoryManageParseColor(_color)
                                .withValues(alpha: 0.2)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: _icon == i
                            ? Border.all(color: categoryManageParseColor(_color))
                            : null,
                      ),
                      child: Icon(categoryManageIconFor(i)),
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
                        color: categoryManageParseColor(c),
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
