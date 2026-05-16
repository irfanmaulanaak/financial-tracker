/// Pure CSV builder. Tested without touching disk/sharing. RFC 4180-ish:
/// quote fields containing comma, quote, or newline; double internal quotes.
library;

String buildCsv(List<List<dynamic>> rows) {
  final buf = StringBuffer();
  for (var r = 0; r < rows.length; r++) {
    final row = rows[r];
    for (var c = 0; c < row.length; c++) {
      if (c > 0) buf.write(',');
      buf.write(_escape(row[c]));
    }
    buf.write('\n');
  }
  return buf.toString();
}

String _escape(Object? v) {
  if (v == null) return '';
  final s = v.toString();
  final needs = s.contains(',') || s.contains('"') || s.contains('\n');
  if (!needs) return s;
  return '"${s.replaceAll('"', '""')}"';
}

/// Expense rows → CSV with header.
String expensesToCsv(
  Iterable<({
    DateTime date,
    int amount,
    String category,
    String paymentMethod,
    String spentBy,
    String? note,
  })> rows,
) {
  final out = <List<dynamic>>[
    ['date', 'amount', 'category', 'paymentMethod', 'spentBy', 'note']
  ];
  for (final r in rows) {
    out.add([
      _isoDate(r.date),
      r.amount,
      r.category,
      r.paymentMethod,
      r.spentBy,
      r.note ?? '',
    ]);
  }
  return buildCsv(out);
}

String _isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
