import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_submit_dot.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import '../investments/investment.dart';
import '../investments/investments_screen.dart' show investmentsProvider;
import 'goal.dart';
import 'goal_repository.dart';
import 'widgets/goal_amount_fields.dart';
import 'widgets/goal_form_parts.dart';
import 'widgets/goal_funding_sheet.dart';
import 'widgets/goal_preset_grid.dart';

/// Full add-goal flow: preset → name + color → target + current with keypad
/// → duration → projection. Mirrors `AddGoalScreen` in
/// `claude-design/screens-extras.jsx`.
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
  int _monthsTo = 12;
  String? _fundingType;
  String? _fundingId;
  bool _busy = false;
  String? _error;

  bool get _linked => _fundingType != null && _fundingId != null;

  static const _monthsList = [3, 6, 12, 24, 36, 60, 120, 180, 240];

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
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
      final current = _linked ? 0 : _current;
      final remaining = (_target - current).clamp(0, _target);
      final monthly = _monthsTo > 0 ? (remaining / _monthsTo).ceil() : 0;
      final dueDate = DateTime(
        DateTime.now().year,
        DateTime.now().month + _monthsTo,
        1,
      );
      final label = _label.text.trim().isEmpty
          ? 'Tujuan Baru'
          : _label.text.trim();
      await ref.read(goalRepositoryProvider).add(
            hid: hid,
            label: label,
            target: _target,
            current: current,
            dueDate: dueDate,
            monthlyContrib: monthly,
            color: _hexFor(_tone),
            icon: _icon,
            scope: GoalScope.shared,
            ownerId: user.uid,
            presetId: _presetId,
            fundingType: _fundingType,
            fundingId: _fundingId,
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

  Future<void> _pickFunding() async {
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return;
    final investments =
        ref.read(investmentsProvider(household.id)).value ??
            const <Investment>[];
    final choice = await showGoalFundingSheet(
      context,
      household: household,
      investments: investments,
      currentKey: _linked ? '$_fundingType:$_fundingId' : null,
    );
    if (choice == null) return;
    FtHaptics.select();
    setState(() {
      _fundingType = choice.type;
      _fundingId = choice.id;
    });
  }

  String _fundingLabel(WidgetRef ref) {
    if (!_linked) return 'Manual (setoran)';
    final household = ref.read(currentHouseholdProvider).value;
    if (household == null) return '-';
    if (_fundingType == 'savings') {
      final acc = household.accountOf(_fundingId!);
      return acc == null ? '-' : '${acc.label} · ${Money.format(acc.value)}';
    }
    final investments =
        ref.read(investmentsProvider(household.id)).value ??
            const <Investment>[];
    for (final inv in investments) {
      if (inv.id == _fundingId) {
        return '${inv.label} · ${Money.format(inv.currentValue)}';
      }
    }
    return '-';
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    // Keep the funding label live while the sheet sources stream in.
    ref.watch(investmentsProvider(household.id));
    final current = _linked ? 0 : _current;
    final remaining = (_target - current).clamp(0, _target);
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
                  current: current,
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
                  target: _target,
                  current: _current,
                  tone: _tone,
                  showCurrent: !_linked,
                  onChangeTarget: (v) => setState(() => _target = v),
                  onChangeCurrent: (v) => setState(() => _current = v),
                ),
                const SizedBox(height: 14),
                const Eyebrow('Sumber Dana'),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickFunding,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: FtColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: FtColors.line, width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _linked ? Icons.link : Icons.edit_outlined,
                          size: 16,
                          color: FtColors.ink2,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _fundingLabel(ref),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: FtColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 18, color: FtColors.ink3),
                      ],
                    ),
                  ),
                ),
                if (_linked) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Progress tujuan mengikuti nilai aset ini — dibagi '
                    'proporsional bila aset dipakai beberapa tujuan.',
                    style: TextStyle(color: FtColors.ink3, fontSize: 11),
                  ),
                ],
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
                    current: current,
                  ),
                ],
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
        ],
      ),
    );
  }
}

String _hexFor(Color c) {
  final v = c.toARGB32() & 0xFFFFFF;
  return '#${v.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
