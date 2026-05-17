import 'package:cloud_firestore/cloud_firestore.dart';

import '../accounts/account.dart';

/// Family-role label. Display only; permission gating is `AccessLevel`.
/// "Other" is a generic fallback.
enum MemberRole { suami, istri, anak, orangTua, other }

String roleToString(MemberRole r) => switch (r) {
      MemberRole.istri => 'Istri',
      MemberRole.suami => 'Suami',
      MemberRole.anak => 'Anak',
      MemberRole.orangTua => 'Orang Tua',
      MemberRole.other => 'Lainnya',
    };

MemberRole roleFromString(String? s) => switch (s) {
      'Istri' => MemberRole.istri,
      'Suami' => MemberRole.suami,
      'Anak' => MemberRole.anak,
      'Orang Tua' => MemberRole.orangTua,
      _ => MemberRole.other,
    };

/// 2-tier permission gating per member, persisted on `members[].accessLevel`
/// and mirrored to the root `memberAccess: {<uid>: 'full'|'limited'}` map for
/// O(1) rule lookups.
///
/// - `full`    → reads everything (incl. balances); writes everything.
/// - `limited` → cannot read balances; writes expenses + incomes only.
///
/// The legacy `view` tier was dropped in SEC-004 (couldn't be enforced as
/// promised without server-built summary docs). Existing `view` rows are
/// migrated to `limited` on next household load — see
/// `viewToLimitedMigrationProvider`.
enum AccessLevel { full, limited }

String accessLevelToString(AccessLevel a) => switch (a) {
      AccessLevel.full => 'full',
      AccessLevel.limited => 'limited',
    };

AccessLevel accessLevelFromString(String? s) => switch (s) {
      'limited' => AccessLevel.limited,
      // Legacy: 'view' tier was removed in SEC-004; treat as 'limited'.
      'view' => AccessLevel.limited,
      _ => AccessLevel.full,
    };

String accessLevelLabel(AccessLevel a) => switch (a) {
      AccessLevel.full => 'Akses Penuh',
      AccessLevel.limited => 'Akses Terbatas',
    };

String accessLevelDetail(AccessLevel a) => switch (a) {
      AccessLevel.full =>
        'Lihat & catat semua transaksi, saldo, tujuan, dan utang.',
      AccessLevel.limited =>
        'Bisa mencatat pengeluaran dan pemasukan. Tidak melihat saldo akun.',
    };

class Member {
  final String userId;
  final String displayName;
  final MemberRole role;
  final String color;
  final DateTime joinedAt;
  final bool isCreator;
  final AccessLevel accessLevel;

  const Member({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.color,
    required this.joinedAt,
    required this.isCreator,
    this.accessLevel = AccessLevel.full,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'role': roleToString(role),
        'color': color,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'isCreator': isCreator,
        'accessLevel': accessLevelToString(accessLevel),
      };

  static Member fromMap(Map<String, dynamic> m) => Member(
        userId: m['userId'] as String,
        displayName: m['displayName'] as String? ?? '',
        role: roleFromString(m['role'] as String?),
        color: m['color'] as String? ?? '#64748B',
        joinedAt: (m['joinedAt'] as Timestamp).toDate(),
        isCreator: m['isCreator'] as bool? ?? false,
        accessLevel: accessLevelFromString(m['accessLevel'] as String?),
      );
}

class Category {
  final String id;
  final String label;
  final String icon;
  final String color;
  final int monthlyBudget;
  final bool archived;
  final int sortOrder;

  const Category({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.monthlyBudget,
    this.archived = false,
    this.sortOrder = 0,
  });

  Category copyWith({
    String? label,
    String? icon,
    String? color,
    int? monthlyBudget,
    bool? archived,
    int? sortOrder,
  }) =>
      Category(
        id: id,
        label: label ?? this.label,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        monthlyBudget: monthlyBudget ?? this.monthlyBudget,
        archived: archived ?? this.archived,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'icon': icon,
        'color': color,
        'monthlyBudget': monthlyBudget,
        'archived': archived,
        'sortOrder': sortOrder,
      };

  static Category fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        label: m['label'] as String? ?? '',
        icon: m['icon'] as String? ?? 'category',
        color: m['color'] as String? ?? '#64748B',
        monthlyBudget: (m['monthlyBudget'] as num?)?.toInt() ?? 0,
        archived: m['archived'] as bool? ?? false,
        sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

class Household {
  final String id;
  final String name;
  final String creatorId;
  final DateTime createdAt;
  final int payday;
  final int monthlyBudgetTotal;
  final List<String> memberIds;
  final List<Member> members;
  final List<Category> categories;

  /// Cash + savings balances. Persisted in `households/{hid}/private/balances`
  /// (SEC-004) — NOT on this doc. `currentHouseholdProvider` populates them
  /// from the balances stream for `full`-tier members; for `limited` they
  /// stay empty (Firestore denies the read).
  final List<Account> cashAccounts;
  final List<Account> savingsAccounts;

  const Household({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.createdAt,
    required this.payday,
    required this.monthlyBudgetTotal,
    required this.memberIds,
    required this.members,
    required this.categories,
    this.cashAccounts = const [],
    this.savingsAccounts = const [],
  });

  /// Returns a copy of this household with the supplied balances merged in.
  Household withBalances({
    required List<Account> cashAccounts,
    required List<Account> savingsAccounts,
  }) =>
      Household(
        id: id,
        name: name,
        creatorId: creatorId,
        createdAt: createdAt,
        payday: payday,
        monthlyBudgetTotal: monthlyBudgetTotal,
        memberIds: memberIds,
        members: members,
        categories: categories,
        cashAccounts: cashAccounts,
        savingsAccounts: savingsAccounts,
      );

  /// Returns the account (cash OR savings) with the given id, or null.
  Account? accountOf(String id) {
    for (final a in cashAccounts) {
      if (a.id == id) return a;
    }
    for (final a in savingsAccounts) {
      if (a.id == id) return a;
    }
    return null;
  }

  Member? memberOf(String uid) {
    for (final m in members) {
      if (m.userId == uid) return m;
    }
    return null;
  }

  Category? categoryOf(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// `memberAccess` is the uid→accessLevel map mirrored from `members[]`.
  /// Stored alongside members so Firestore rules can look up the caller's
  /// access level in O(1) without scanning the array.
  static Map<String, String> memberAccessMap(List<Member> members) => {
        for (final m in members) m.userId: accessLevelToString(m.accessLevel),
      };

  Map<String, dynamic> toMap() => {
        'name': name,
        'creatorId': creatorId,
        'createdAt': Timestamp.fromDate(createdAt),
        'payday': payday,
        'currency': 'IDR',
        'locale': 'id-ID',
        'monthlyBudgetTotal': monthlyBudgetTotal,
        'memberIds': memberIds,
        'members': members.map((m) => m.toMap()).toList(),
        'memberAccess': memberAccessMap(members),
        'categories': categories.map((c) => c.toMap()).toList(),
        // Balances live at `households/{hid}/private/balances` since SEC-004.
        'schemaVersion': 3,
      };

  static Household fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return Household(
      id: snap.id,
      name: m['name'] as String? ?? '',
      creatorId: m['creatorId'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      payday: (m['payday'] as num?)?.toInt() ?? 30,
      monthlyBudgetTotal: (m['monthlyBudgetTotal'] as num?)?.toInt() ?? 0,
      memberIds: List<String>.from(m['memberIds'] as List? ?? const []),
      members: ((m['members'] as List?) ?? const [])
          .map((e) => Member.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      categories: ((m['categories'] as List?) ?? const [])
          .map((e) => Category.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
