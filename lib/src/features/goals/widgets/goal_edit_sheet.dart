import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/formatters.dart';
import '../goal.dart';

class GoalDraft {
  final String label;
  final int target;
  final int monthlyContrib;
  final DateTime? dueDate;
  final String icon;
  final String color;
  final GoalScope scope;
  final String? ownerId;
  const GoalDraft({
    required this.label,
    required this.target,
    required this.monthlyContrib,
    required this.dueDate,
    required this.icon,
    required this.color,
    required this.scope,
    required this.ownerId,
  });
}

class GoalEditSheet extends ConsumerStatefulWidget {
  const GoalEditSheet({super.key, required this.currentUid});
  final String currentUid;

  @override
  ConsumerState<GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends ConsumerState<GoalEditSheet> {
  final _label = TextEditingController();
  final _target = TextEditingController();
  final _monthly = TextEditingController();
  DateTime? _due;
  GoalScope _scope = GoalScope.shared;
  String _icon = 'savings';
  String _color = '#10B981';

  static const _icons = [
    'savings',
    'flight',
    'home',
    'school',
    'directions_car',
    'celebration',
  ];
  static const _colors = [
    '#10B981',
    '#3B82F6',
    '#EC4899',
    '#F59E0B',
    '#8B5CF6',
    '#0EA5E9',
  ];

  @override
  void dispose() {
    _label.dispose();
    _target.dispose();
    _monthly.dispose();
    super.dispose();
  }

  void _save() {
    final label = _label.text.trim();
    final target = int.tryParse(_target.text) ?? 0;
    if (label.isEmpty || target <= 0) return;
    Navigator.pop(
      context,
      GoalDraft(
        label: label,
        target: target,
        monthlyContrib: int.tryParse(_monthly.text) ?? 0,
        dueDate: _due,
        icon: _icon,
        color: _color,
        scope: _scope,
        ownerId: _scope == GoalScope.personal ? widget.currentUid : null,
      ),
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
            Text('Tujuan baru', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _label,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama tujuan',
                hintText: 'Dana darurat',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _target,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Target',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _monthly,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Kontribusi bulanan (opsional)',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      _due ?? DateTime.now().add(const Duration(days: 365)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
                );
                if (picked != null) setState(() => _due = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Target tanggal (opsional)',
                ),
                child: Text(_due == null ? 'Tidak diset' : Dates.short(_due!)),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<GoalScope>(
              segments: const [
                ButtonSegment(value: GoalScope.shared, label: Text('Bersama')),
                ButtonSegment(
                  value: GoalScope.personal,
                  label: Text('Pribadi'),
                ),
              ],
              selected: {_scope},
              onSelectionChanged: (s) => setState(() => _scope = s.first),
            ),
            const SizedBox(height: 12),
            const Text('Ikon'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final i in _icons)
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
            const SizedBox(height: 12),
            const Text('Warna'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: [
                for (final c in _colors)
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
            FilledButton(onPressed: _save, child: const Text('Buat tujuan')),
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
      'savings' => Icons.savings,
      'flight' => Icons.flight_takeoff,
      'home' => Icons.home,
      'school' => Icons.school,
      'directions_car' => Icons.directions_car,
      'celebration' => Icons.celebration,
      _ => Icons.flag,
    };
