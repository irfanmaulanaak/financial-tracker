import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// IDR + id-ID formatting helpers. Locked currency; no multi-currency support.
class Money {
  static final _idr = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  );

  /// Formats integer rupiah as "Rp1.234.567".
  static String format(num amount) => _idr.format(amount);

  /// Parses user input like "Rp 1.234.567" or "1234567" into an int (rupiah).
  /// Returns null if no digits found.
  static int? parse(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  /// Returns the digit-grouped seed for a `TextEditingController` ("1.000.000",
  /// empty when zero). Strips the "Rp" prefix from [format].
  static String displayDigits(int amount) =>
      amount == 0 ? '' : format(amount).replaceFirst(RegExp(r'^Rp\s*'), '');
}

/// Input formatter that re-groups digits into id-ID style (`1.000.000`).
/// Cursor always settles at end-of-text after reformatting.
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final n = int.parse(digits);
    final grouped = Money.format(n).replaceFirst(RegExp(r'^Rp\s*'), '');
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: grouped.length),
    );
  }
}

class Dates {
  static final _short = DateFormat('d MMM y', 'id_ID');
  static final _grouped = DateFormat('EEEE, d MMM y', 'id_ID');
  static final _monthYear = DateFormat('MMM y', 'id_ID');
  static final _month = DateFormat('MMM', 'id_ID');
  static final _dayMonth = DateFormat('d MMM', 'id_ID');

  static String short(DateTime d) => _short.format(d);
  static String grouped(DateTime d) => _grouped.format(d);
  static String monthYear(DateTime d) => _monthYear.format(d);
  static String month(DateTime d) => _month.format(d);

  /// "25 Apr" — used for compact cycle-range labels.
  static String dayMonth(DateTime d) => _dayMonth.format(d);

  /// "25 Apr–24 Mei" — inclusive range label for a payday cycle, where
  /// [endExclusive] is the next cycle's start.
  static String cycleRange(DateTime start, DateTime endExclusive) {
    final endInclusive = endExclusive.subtract(const Duration(days: 1));
    return '${dayMonth(start)}–${dayMonth(endInclusive)}';
  }

  /// Returns midnight of the local day for `d` (used to group expenses).
  static DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);
}
