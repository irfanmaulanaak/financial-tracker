/// Cash & savings accounts. Embedded as arrays on the household doc (bounded
/// set per household). Money values are integer IDR.
library;

enum AccountKind { cash, savings }

class Account {
  final String id;
  final AccountKind kind;
  final String label;
  final String? hint;
  final int value;
  final int sortOrder;

  const Account({
    required this.id,
    required this.kind,
    required this.label,
    required this.hint,
    required this.value,
    required this.sortOrder,
  });

  Account copyWith({
    String? label,
    String? hint,
    int? value,
    int? sortOrder,
  }) =>
      Account(
        id: id,
        kind: kind,
        label: label ?? this.label,
        hint: hint ?? this.hint,
        value: value ?? this.value,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        if (hint != null) 'hint': hint,
        'value': value,
        'sortOrder': sortOrder,
      };

  static Account fromMap(Map<String, dynamic> m, AccountKind kind) => Account(
        id: m['id'] as String,
        kind: kind,
        label: m['label'] as String? ?? '',
        hint: m['hint'] as String?,
        value: (m['value'] as num?)?.toInt() ?? 0,
        sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
      );
}
