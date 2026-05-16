import 'package:cloud_firestore/cloud_firestore.dart';

import '../accounts/account.dart';

/// Roles are labels only — no permission gating. "Other" is a generic fallback.
enum MemberRole { istri, suami, anak, other }

String roleToString(MemberRole r) => switch (r) {
      MemberRole.istri => 'Istri',
      MemberRole.suami => 'Suami',
      MemberRole.anak => 'Anak',
      MemberRole.other => 'Other',
    };

MemberRole roleFromString(String? s) => switch (s) {
      'Istri' => MemberRole.istri,
      'Suami' => MemberRole.suami,
      'Anak' => MemberRole.anak,
      _ => MemberRole.other,
    };

class Member {
  final String userId;
  final String displayName;
  final MemberRole role;
  final String color;
  final DateTime joinedAt;
  final bool isCreator;

  const Member({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.color,
    required this.joinedAt,
    required this.isCreator,
  });

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'displayName': displayName,
        'role': roleToString(role),
        'color': color,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'isCreator': isCreator,
      };

  static Member fromMap(Map<String, dynamic> m) => Member(
        userId: m['userId'] as String,
        displayName: m['displayName'] as String? ?? '',
        role: roleFromString(m['role'] as String?),
        color: m['color'] as String? ?? '#64748B',
        joinedAt: (m['joinedAt'] as Timestamp).toDate(),
        isCreator: m['isCreator'] as bool? ?? false,
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

class PaymentMethod {
  final String id;
  final String label;
  final String type;
  final bool builtIn;

  const PaymentMethod({
    required this.id,
    required this.label,
    required this.type,
    this.builtIn = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'label': label,
        'type': type,
        'builtIn': builtIn,
      };

  static PaymentMethod fromMap(Map<String, dynamic> m) => PaymentMethod(
        id: m['id'] as String,
        label: m['label'] as String? ?? '',
        type: m['type'] as String? ?? 'cash',
        builtIn: m['builtIn'] as bool? ?? false,
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
  final List<PaymentMethod> paymentMethods;
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
    required this.paymentMethods,
    this.cashAccounts = const [],
    this.savingsAccounts = const [],
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

  PaymentMethod? paymentMethodOf(String id) {
    for (final p in paymentMethods) {
      if (p.id == id) return p;
    }
    return null;
  }

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
        'categories': categories.map((c) => c.toMap()).toList(),
        'paymentMethods': paymentMethods.map((p) => p.toMap()).toList(),
        'cashAccounts': cashAccounts.map((a) => a.toMap()).toList(),
        'savingsAccounts': savingsAccounts.map((a) => a.toMap()).toList(),
        'schemaVersion': 1,
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
      paymentMethods: ((m['paymentMethods'] as List?) ?? const [])
          .map((e) =>
              PaymentMethod.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      cashAccounts: ((m['cashAccounts'] as List?) ?? const [])
          .map((e) => Account.fromMap(
              Map<String, dynamic>.from(e as Map), AccountKind.cash))
          .toList(),
      savingsAccounts: ((m['savingsAccounts'] as List?) ?? const [])
          .map((e) => Account.fromMap(
              Map<String, dynamic>.from(e as Map), AccountKind.savings))
          .toList(),
    );
  }
}
