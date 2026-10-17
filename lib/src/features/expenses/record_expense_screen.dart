import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/category_suggester.dart';
import '../../core/catat_card.dart';
import '../../core/envelope.dart';
import '../../core/formatters.dart';
import '../../core/payday.dart';
import '../../core/providers.dart';
import '../../theme.dart';
import '../../ui/ft_celebrate.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_input.dart';
import '../../ui/ft_submit_dot.dart';
import '../../ui/ft_ui.dart';
import '../cards/credit_card.dart';
import '../cards/cards_screen.dart';
import '../home/eling/catat_saved_card.dart';
import '../household/household.dart';
import '../household/household_providers.dart';
import '../insights/insights_providers.dart' show previousCyclesExpensesProvider;
import '../record_common/account_picker.dart';
import '../record_common/card_picker.dart';
import '../record_common/category_chip_row.dart';
import '../record_common/installment_picker.dart';
import '../record_common/meta_row.dart';
import '../record_common/money_field.dart';
import '../record_common/pay_type_toggle.dart';
import 'expense.dart';
import 'expense_favorites_row.dart';
import 'expense_providers.dart';
import 'expense_repository.dart';
import 'favorite_expenses.dart';
import 'split_expense_sheet.dart';
import 'widgets/record_expense_extras.dart';

part 'widgets/record_expense_form.dart';
part 'widgets/record_expense_actions.dart';

const _kLastPayType = 'record_last_pay_type';
const _kLastAccount = 'record_last_account';
const _kLastCard = 'record_last_card';

class RecordExpenseScreen extends ConsumerStatefulWidget {
  const RecordExpenseScreen({super.key, this.initial});

  /// When set, the screen runs in edit mode: prefills all fields and writes
  /// via `ExpenseRepository.update` instead of `add*`.
  final Expense? initial;

  bool get isEdit => initial != null;
  bool get isCicilan => initial?.installmentPlanId != null;

  @override
  ConsumerState<RecordExpenseScreen> createState() =>
      _RecordExpenseScreenState();
}

class _RecordExpenseScreenState extends ConsumerState<RecordExpenseScreen> {
  int _amount = 0;
  String? _categoryId;
  String _payType = 'cash'; // 'cash' | 'credit'
  String? _sourceAccountId;
  String? _cardId;
  String? _spentBy;
  DateTime _date = DateTime.now();
  final _note = TextEditingController();
  bool _recurring = false;
  bool _cicilan = false;
  int _cicilanMonths = 6;
  double _cicilanApr = 0.0;
  bool _busy = false;
  String? _error;

  /// True once the user explicitly tapped a category chip (or edit mode):
  /// suggestion & most-used defaults stop overriding their choice.
  bool _categoryTouched = false;

  /// Category id auto-applied from the note's keywords — drives the
  /// "disarankan" hint next to the Kategori eyebrow.
  String? _suggestedCategoryId;

  /// Payment defaults wait until the last-used prefs have loaded, so a
  /// remembered account/card wins over "first in list".
  bool _prefsLoaded = false;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      _amount = init.amount;
      _categoryId = init.categoryId;
      _payType = init.cardId != null ? 'credit' : 'cash';
      _sourceAccountId = init.sourceAccountId;
      _cardId = init.cardId;
      _spentBy = init.spentBy;
      _date = init.date;
      _note.text = init.note ?? '';
      _recurring = init.recurring;
      _cicilan = init.installmentPlanId != null;
      _categoryTouched = true;
      _prefsLoaded = true;
    } else {
      _note.addListener(_onNoteChanged);
      // ignore: discarded_futures
      SharedPreferences.getInstance().then((p) {
        if (!mounted) return;
        setState(() {
          _prefsLoaded = true;
          final pt = p.getString(_kLastPayType);
          if (pt == 'cash' || pt == 'credit') _payType = pt!;
          _sourceAccountId ??= p.getString(_kLastAccount);
          _cardId ??= p.getString(_kLastCard);
        });
      });
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// setState is `@protected`, so the `part` extensions (form/actions) can't
  /// call it directly. They route through this same-library wrapper instead.
  void _rebuild(VoidCallback fn) => setState(fn);

  @override
  Widget build(BuildContext context) => buildContent(context);
}
