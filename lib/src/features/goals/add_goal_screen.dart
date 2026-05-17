import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_submit_dot.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import '../record_common/keypad.dart';
import 'goal.dart';
import 'goal_repository.dart';
import 'widgets/goal_amount_fields.dart';
import 'widgets/goal_form_parts.dart';
import 'widgets/goal_preset_grid.dart';
import 'widgets/goal_source_picker.dart';

/// Full add-goal flow: preset → name + color → target + current with keypad
/// → duration → projection → source account → auto-debit toggle. Mirrors
/// `AddGoalScreen` in `claude-design/screens-extras.jsx`.
class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({super.key});

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _label = TextEditingController();
  String? _presetId;
  String _icon = 'flag';
  Color _tone = FtColors.clay;
  int _target = 0;
  int _current = 0;
  GoalAmountField _activeField = GoalAmountField.target;
  int _monthsTo = 12;
  String? _sourceAccountId;
  bool _autoDebit = true;
  bool _busy = false;
  String? _error;

  static const _monthsList = [3, 6, 12, 18, 24, 36, 60];

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _tapKey(String k) {
    FtHaptics.tap();
    setState(() {
      if (_activeField == GoalAmountField.target) {
        _target = applyRecordKey(_target, k);
      } else {
        _current = applyRecordKey(_current, k);
      }
    });
  }

  void _selectPreset(GoalPreset p) {
    FtHaptics.select();
    setState(() {
      _presetId = p.id;
      _icon = p.icon;
      _tone = p.color;
      if (_label.text.isEmpty && p.id != 'other') _label.text = p.label;
    });
  }

  Future<void> _submit() async {
    if (_target <= 0) {
      FtHaptics.warning();
      setState(() => _error = 'Atur target dulu');
      return;
    }
    final hid = ref.read(currentHouseholdProvider).value?.id;
    final user = ref.read(authStateProvider).value;
    if (hid == null || user == null) return;
    FtHaptics.tap();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final remaining = (_target - _current).clamp(0, _target);
      final monthly = _monthsTo > 0 ? (remaining / _monthsTo).ceil() : 0;
      final dueDate = DateTime(
        DateTime.now().year,
        DateTime.now().month + _monthsTo,
        1,
      );
      final autoDebit = _autoDebit &&
          _sourceAccountId != null &&
          monthly > 0;
      final label = _label.text.trim().isEmpty
          ? 'Tujuan Baru'
          : _label.text.trim();
      await ref.read(goalRepositoryProvider).add(
            hid: hid,
            label: label,
            target: _target,
            current: _current,
            dueDate: dueDate,
            monthlyContrib: monthly,
            color: _hexFor(_tone),
            icon: _icon,
            scope: GoalScope.shared,
            ownerId: user.uid,
            autoDebit: autoDebit,
            autoDebitDay: 1,
            sourceAccountId: _sourceAccountId,
            presetId: _presetId,
          );
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Gagal menyimpan: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cashAccounts = household.cashAccounts;
    if (_sourceAccountId == null && cashAccounts.isNotEmpty) {
      _sourceAccountId = cashAccounts.first.id;
    }
    final remaining = (_target - _current).clamp(0, _target);
    final monthly = _monthsTo > 0 ? (remaining / _monthsTo).ceil() : 0;

    return Scaffold(
      backgroundColor: FtColors.bg,
      body: Column(
        children: [
          FtSubHeader(
            title: 'Buat Tujuan Baru',
            trailing: FtSubmitDot(
              busy: _busy,
              enabled: _target > 0,
              activeColor: _tone,
              onTap: _submit,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 16),
              children: [
                GoalPreviewHero(
                  icon: _icon,
                  label: _label.text.trim(),
                  tone: _tone,
                  target: _target,
                  current: _current,
                  monthly: monthly,
                  monthsTo: _monthsTo,
                ),
                const SizedBox(height: 14),
                const Eyebrow('Template Tujuan'),
                const SizedBox(height: 8),
                GoalPresetGrid(
                  presets: goalPresets(),
                  activeId: _presetId,
                  onSelect: _selectPreset,
                ),
                const SizedBox(height: 14),
                const Eyebrow('Nama Tujuan'),
                const SizedBox(height: 8),
                TextField(
                  controller: _label,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Misal: Dana Darurat Keluarga',
                  ),
                ),
                const SizedBox(height: 14),
                const Eyebrow('Aksen Warna'),
                const SizedBox(height: 8),
                GoalToneRow(
                  tone: _tone,
                  onChange: (c) {
                    FtHaptics.select();
                    setState(() => _tone = c);
                  },
                ),
                const SizedBox(height: 14),
                const Eyebrow('Jumlah'),
                const SizedBox(height: 8),
                GoalAmountFields(
                  activeField: _activeField,
                  target: _target,
                  current: _current,
                  tone: _tone,
                  onSelect: (f) {
                    FtHaptics.select();
                    setState(() => _activeField = f);
                  },
                ),
                const SizedBox(height: 14),
                GoalMonthsRow(
                  monthsTo: _monthsTo,
                  monthsList: _monthsList,
                  onChange: (m) {
                    FtHaptics.select();
                    setState(() => _monthsTo = m);
                  },
                ),
                if (_target > 0) ...[
                  const SizedBox(height: 14),
                  GoalProjectionCard(
                    tone: _tone,
                    monthly: monthly,
                    monthsTo: _monthsTo,
                    current: _current,
                  ),
                ],
                const SizedBox(height: 14),
                const Eyebrow('Sumber Dana Bulanan'),
                const SizedBox(height: 8),
                GoalSourceAccounts(
                  accounts: cashAccounts,
                  selectedId: _sourceAccountId,
                  tone: _tone,
                  onSelect: (id) {
                    FtHaptics.select();
                    setState(() => _sourceAccountId = id);
                  },
                ),
                const SizedBox(height: 8),
                GoalAutoDebitToggle(
                  value: _autoDebit,
                  tone: _tone,
                  onChange: (v) {
                    FtHaptics.select();
                    setState(() => _autoDebit = v);
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: FtColors.danger, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
          RecordKeypad(onTap: _tapKey),
        ],
      ),
    );
  }
}

String _hexFor(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
