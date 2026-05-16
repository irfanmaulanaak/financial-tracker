import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import 'goal.dart';
import 'goal_repository.dart';

final goalsProvider = StreamProvider.family<List<Goal>, String>((ref, hid) {
  return ref.watch(goalRepositoryProvider).watchAll(hid);
});

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final goalsAsync = ref.watch(goalsProvider(household.id));

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (goals) {
          final totalTarget = goals.fold<int>(0, (a, b) => a + b.target);
          final totalCurrent = goals.fold<int>(0, (a, b) => a + b.current);
          return FtAppChrome(
            current: FtTab.goals,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 120),
              children: [
                FtSubHeader(
                  title: 'Tujuan',
                  trailing: IconButton.filled(
                    onPressed: () =>
                        _openSheet(context, ref, household.id, user.uid),
                    icon: const Icon(Icons.add),
                  ),
                ),
                FtCard(
                  margin: const EdgeInsets.fromLTRB(22, 4, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Tujuan Finansial'),
                      const SizedBox(height: 6),
                      Text(
                        Money.format(totalCurrent),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'dari ${Money.format(totalTarget)} target',
                        style: const TextStyle(
                          color: FtColors.ink3,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FtProgressBar(
                        value: totalCurrent,
                        max: totalTarget <= 0 ? 1 : totalTarget,
                        color: FtColors.moss,
                        height: 6,
                      ),
                    ],
                  ),
                ),
                if (goals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'Belum ada tujuan.\nMis. dana darurat, liburan, beli rumah.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: FtColors.ink3),
                      ),
                    ),
                  )
                else
                  for (final g in goals)
                    _GoalCard(
                      goal: g,
                      ownerLabel: g.ownerId != null
                          ? household.memberOf(g.ownerId!)?.displayName ?? '-'
                          : 'Bersama',
                      onContribute: () =>
                          _openContributeSheet(context, ref, household.id, g),
                      onDelete: () =>
                          _confirmDelete(context, ref, household.id, g),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref,
    String hid,
    String currentUid,
  ) async {
    final result = await showModalBottomSheet<_GoalDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _GoalEditSheet(currentUid: currentUid),
    );
    if (result == null) return;
    await ref
        .read(goalRepositoryProvider)
        .add(
          hid: hid,
          label: result.label,
          target: result.target,
          dueDate: result.dueDate,
          monthlyContrib: result.monthlyContrib,
          color: result.color,
          icon: result.icon,
          scope: result.scope,
          ownerId: result.ownerId,
        );
  }

  Future<void> _openContributeSheet(
    BuildContext context,
    WidgetRef ref,
    String hid,
    Goal goal,
  ) async {
    final ctrl = TextEditingController();
    final amount = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tambah ke ${goal.label}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final v = int.tryParse(ctrl.text);
                if (v == null || v <= 0) return;
                Navigator.pop(context, v);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (amount != null) {
      await ref
          .read(goalRepositoryProvider)
          .contribute(hid: hid, goalId: goal.id, amount: amount);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String hid,
    Goal goal,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Hapus "${goal.label}"?'),
        content: const Text('Tidak bisa dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(goalRepositoryProvider).delete(hid: hid, goalId: goal.id);
    }
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.ownerLabel,
    required this.onContribute,
    required this.onDelete,
  });
  final Goal goal;
  final String ownerLabel;
  final VoidCallback onContribute;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(goal.color);
    final months = monthsToGoal(
      target: goal.target,
      current: goal.current,
      monthlyContrib: goal.monthlyContrib,
    );
    return FtCard(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 12),
      child: Padding(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Icon(_iconFor(goal.icon), color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.label,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$ownerLabel • ${goalScopeLabel(goal.scope)}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${Money.format(goal.current)} / ${Money.format(goal.target)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (goal.isComplete)
                  const Chip(
                    label: Text('Tercapai'),
                    visualDensity: VisualDensity.compact,
                  )
                else if (months != null)
                  Text(
                    '±$months bln lagi',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  )
                else
                  Text(
                    'Sisa ${Money.format(goal.remaining)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: goal.isComplete ? null : onContribute,
              child: const Text('Tambah dana'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalDraft {
  final String label;
  final int target;
  final int monthlyContrib;
  final DateTime? dueDate;
  final String icon;
  final String color;
  final GoalScope scope;
  final String? ownerId;
  const _GoalDraft({
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

class _GoalEditSheet extends ConsumerStatefulWidget {
  const _GoalEditSheet({required this.currentUid});
  final String currentUid;

  @override
  ConsumerState<_GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends ConsumerState<_GoalEditSheet> {
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
      _GoalDraft(
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
