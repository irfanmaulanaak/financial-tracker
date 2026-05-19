import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalScope { shared, personal }

String goalScopeLabel(GoalScope s) => s == GoalScope.shared ? 'Bersama' : 'Pribadi';

GoalScope goalScopeFromString(String? s) =>
    s == 'shared' ? GoalScope.shared : GoalScope.personal;

class Goal {
  final String id;
  final String label;
  final int target;
  final int current;
  final DateTime? dueDate;
  final int monthlyContrib;
  final String icon;
  final String color;
  final GoalScope scope;
  final String? ownerId; // null for shared
  final DateTime createdAt;

  /// Optional preset id from the add-goal flow (`emergency`, `vacation`,
  /// `house`, `gadget`, `wedding`, `other`). Decorative only; doesn't drive
  /// behavior.
  final String? presetId;

  /// Manual sort key for drag-to-reorder on the Tujuan list. Lower comes
  /// first. Null = legacy goal; sorts by `createdAt.millisecondsSinceEpoch`
  /// as fallback so the list stays stable until the user reorders.
  final int? sortIndex;

  const Goal({
    required this.id,
    required this.label,
    required this.target,
    required this.current,
    required this.dueDate,
    required this.monthlyContrib,
    required this.icon,
    required this.color,
    required this.scope,
    required this.ownerId,
    required this.createdAt,
    this.presetId,
    this.sortIndex,
  });

  double get progress => target == 0 ? 0 : (current / target).clamp(0, 1);
  int get remaining => (target - current).clamp(0, target);
  bool get isComplete => current >= target;

  Map<String, dynamic> toMap() => {
        'label': label,
        'target': target,
        'current': current,
        if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
        'monthlyContrib': monthlyContrib,
        'icon': icon,
        'color': color,
        'scope': scope.name,
        if (ownerId != null) 'ownerId': ownerId,
        'createdAt': Timestamp.fromDate(createdAt),
        if (presetId != null) 'presetId': presetId,
        if (sortIndex != null) 'sortIndex': sortIndex,
      };

  static Goal fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return Goal(
      id: snap.id,
      label: m['label'] as String? ?? '',
      target: (m['target'] as num?)?.toInt() ?? 0,
      current: (m['current'] as num?)?.toInt() ?? 0,
      dueDate: (m['dueDate'] as Timestamp?)?.toDate(),
      monthlyContrib: (m['monthlyContrib'] as num?)?.toInt() ?? 0,
      icon: m['icon'] as String? ?? 'savings',
      color: m['color'] as String? ?? '#10B981',
      scope: goalScopeFromString(m['scope'] as String?),
      ownerId: m['ownerId'] as String?,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      presetId: m['presetId'] as String?,
      sortIndex: (m['sortIndex'] as num?)?.toInt(),
    );
  }
}

/// Pure helper: months remaining to hit target at current monthly contribution.
/// Returns null when target already met OR when no monthly contribution is set.
int? monthsToGoal({
  required int target,
  required int current,
  required int monthlyContrib,
}) {
  if (current >= target) return 0;
  if (monthlyContrib <= 0) return null;
  final remaining = target - current;
  return (remaining / monthlyContrib).ceil();
}

/// Pure helper: monthly contribution required to reach `target` by `dueDate`
/// from `current`, assuming `today`. Returns 0 if already met or no due date.
int requiredMonthlyContribution({
  required int target,
  required int current,
  required DateTime? dueDate,
  required DateTime today,
}) {
  if (current >= target || dueDate == null) return 0;
  final remaining = target - current;
  final months = ((dueDate.year - today.year) * 12 +
          (dueDate.month - today.month))
      .clamp(1, 1 << 30);
  return (remaining / months).ceil();
}
