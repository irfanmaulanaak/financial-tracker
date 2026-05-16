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
}

class Dates {
  static final _short = DateFormat('d MMM y', 'id_ID');
  static final _grouped = DateFormat('EEEE, d MMM y', 'id_ID');

  static String short(DateTime d) => _short.format(d);
  static String grouped(DateTime d) => _grouped.format(d);

  /// Returns midnight of the local day for `d` (used to group expenses).
  static DateTime dayKey(DateTime d) => DateTime(d.year, d.month, d.day);
}
