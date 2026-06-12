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

/// 3-tier permission gating per member, persisted on `members[].accessLevel`.
/// - `full`    → all writes (expenses, incomes, cards, goals, settings).
/// - `limited` → expenses + incomes only.
/// - `view`    → no writes.
enum AccessLevel { full, limited, view }

String accessLevelToString(AccessLevel a) => switch (a) {
      AccessLevel.full => 'full',
      AccessLevel.limited => 'limited',
      AccessLevel.view => 'view',
    };

AccessLevel accessLevelFromString(String? s) => switch (s) {
      'limited' => AccessLevel.limited,
      'view' => AccessLevel.view,
      _ => AccessLevel.full,
    };

String accessLevelLabel(AccessLevel a) => switch (a) {
      AccessLevel.full => 'Akses Penuh',
      AccessLevel.limited => 'Akses Terbatas',
      AccessLevel.view => 'Lihat Saja',
    };

String accessLevelDetail(AccessLevel a) => switch (a) {
      AccessLevel.full =>
        'Lihat & catat semua transaksi, saldo, tujuan, dan utang.',
      AccessLevel.limited =>
        'Hanya bisa mencatat pengeluaran sendiri. Tidak lihat saldo.',
      AccessLevel.view => 'Hanya melihat ringkasan bulanan. Tidak dapat mencatat.',
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

  /// Investment categories (e.g. "Investasi"): their expenses stay in
  /// activity lists but are excluded from total-spend aggregates — buying
  /// an instrument is saving, not consumption.
  final bool isInvestment;

  /// Envelope rollover: leftover budget from the previous cycle is added on
  /// top of this cycle's budget (one-cycle lookback, never negative). See
  /// `core/envelope.dart`.
  final bool rollover;

  /// ZISWAF (zakat/infak/sedekah/wakaf): pengeluarannya direkap total
  /// tahunannya di layar Rekap — membantu hitung zakat & niat sedekah.
  final bool ziswaf;

  const Category({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
    required this.monthlyBudget,
    this.archived = false,
    this.sortOrder = 0,
    this.isInvestment = false,
    this.rollover = false,
    this.ziswaf = false,
  });

  Category copyWith({
    String? label,
    String? icon,
    String? color,
    int? monthlyBudget,
    bool? archived,
    int? sortOrder,
    bool? isInvestment,
    bool? rollover,
    bool? ziswaf,
  }) =>
      Category(
        id: id,
        label: label ?? this.label,
        icon: icon ?? this.icon,
        color: color ?? this.color,
        monthlyBudget: monthlyBudget ?? this.monthlyBudget,
        archived: archived ?? this.archived,
        sortOrder: sortOrder ?? this.sortOrder,
        isInvestment: isInvestment ?? this.isInvestment,
        rollover: rollover ?? this.rollover,
        ziswaf: ziswaf ?? this.ziswaf,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'icon': icon,
        'color': color,
        'monthlyBudget': monthlyBudget,
        'archived': archived,
        'sortOrder': sortOrder,
        'isInvestment': isInvestment,
        'rollover': rollover,
        'ziswaf': ziswaf,
      };

  static Category fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        label: m['label'] as String? ?? '',
        icon: m['icon'] as String? ?? 'category',
        color: m['color'] as String? ?? '#64748B',
        monthlyBudget: (m['monthlyBudget'] as num?)?.toInt() ?? 0,
        archived: m['archived'] as bool? ?? false,
        sortOrder: (m['sortOrder'] as num?)?.toInt() ?? 0,
        isInvestment: m['isInvestment'] as bool? ?? false,
        rollover: m['rollover'] as bool? ?? false,
        ziswaf: m['ziswaf'] as bool? ?? false,
      );
}

/// Satu kejadian "geser anggaran" antar kategori — jejak siapa/kapan,
/// disimpan di doc household (array kecil, dibatasi 30 terbaru).
class BudgetMove {
  const BudgetMove({
    required this.fromId,
    required this.toId,
    required this.amount,
    required this.by,
    required this.at,
  });

  final String fromId;
  final String toId;
  final int amount;

  /// uid anggota yang menggeser.
  final String by;
  final DateTime at;

  Map<String, dynamic> toMap() => {
        'fromId': fromId,
        'toId': toId,
        'amount': amount,
        'by': by,
        'at': Timestamp.fromDate(at),
      };

  static BudgetMove fromMap(Map<String, dynamic> m) => BudgetMove(
        fromId: m['fromId'] as String? ?? '',
        toId: m['toId'] as String? ?? '',
        amount: (m['amount'] as num?)?.toInt() ?? 0,
        by: m['by'] as String? ?? '',
        at: (m['at'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
  final List<Account> cashAccounts;
  final List<Account> savingsAccounts;

  /// Log geser anggaran, terbaru di depan (maks 30 — lihat
  /// `core/budget_move.dart`).
  final List<BudgetMove> budgetMoves;

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
    this.budgetMoves = const [],
  });

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

  /// IDs of investment categories — expenses in these are excluded from
  /// total-spend aggregates (see [Category.isInvestment]).
  Set<String> get investmentCategoryIds =>
      {for (final c in categories) if (c.isInvestment) c.id};

  /// IDs of ZISWAF categories (see [Category.ziswaf]).
  Set<String> get ziswafCategoryIds =>
      {for (final c in categories) if (c.ziswaf) c.id};

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
        'cashAccounts': cashAccounts.map((a) => a.toMap()).toList(),
        'savingsAccounts': savingsAccounts.map((a) => a.toMap()).toList(),
        if (budgetMoves.isNotEmpty)
          'budgetMoves': budgetMoves.map((b) => b.toMap()).toList(),
        'schemaVersion': 2,
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
      cashAccounts: ((m['cashAccounts'] as List?) ?? const [])
          .map((e) => Account.fromMap(
              Map<String, dynamic>.from(e as Map), AccountKind.cash))
          .toList(),
      savingsAccounts: ((m['savingsAccounts'] as List?) ?? const [])
          .map((e) => Account.fromMap(
              Map<String, dynamic>.from(e as Map), AccountKind.savings))
          .toList(),
      budgetMoves: ((m['budgetMoves'] as List?) ?? const [])
          .map((e) => BudgetMove.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
