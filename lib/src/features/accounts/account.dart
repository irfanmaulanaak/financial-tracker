/// Cash & savings accounts. Embedded as arrays on the household doc (bounded
/// set per household). Money values are integer IDR.
library;

enum AccountKind { cash, savings }

/// Sub-classification for cash accounts. Savings accounts ignore this and are
/// always treated as bank-like by consumers (filters, pickers).
enum AccountSubKind { bank, ewallet }

String accountSubKindToString(AccountSubKind s) => switch (s) {
      AccountSubKind.bank => 'bank',
      AccountSubKind.ewallet => 'ewallet',
    };

AccountSubKind accountSubKindFromString(String? s) => switch (s) {
      'ewallet' => AccountSubKind.ewallet,
      _ => AccountSubKind.bank,
    };

String accountSubKindLabel(AccountSubKind s) => switch (s) {
      AccountSubKind.bank => 'Bank',
      AccountSubKind.ewallet => 'E-wallet',
    };

class Account {
  final String id;
  final AccountKind kind;
  final AccountSubKind subKind;
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
    this.subKind = AccountSubKind.bank,
  });

  Account copyWith({
    String? label,
    String? hint,
    int? value,
    int? sortOrder,
    AccountSubKind? subKind,
  }) =>
      Account(
        id: id,
        kind: kind,
        subKind: subKind ?? this.subKind,
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
        // Persist subKind only on cash accounts; savings accounts ignore it.
        if (kind == AccountKind.cash)
          'subKind': accountSubKindToString(subKind),
      };

  static Account fromMap(Map<String, dynamic> m, AccountKind kind) => Account(
        id: m['id'] as String,
        kind: kind,
        subKind: accountSubKindFromString(m['subKind'] as String?),
        label: m['label'] as String? ?? '',
        hint: m['hint'] as String?,
        value: (m['value'] as num?)?.toInt() ?? 0,
        sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
      );
}
