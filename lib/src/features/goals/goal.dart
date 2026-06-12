import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalScope { shared, personal }

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

  /// Sumber dana goal. Null = manual (setoran). `savings` = rekening
  /// tabungan di household, `investment` = posisi investasi. Goal linked
  /// tidak pakai setoran; `current`-nya dihitung dari nilai aset
  /// (proporsional bila aset dipakai beberapa goal) — lihat
  /// `core/goal_funding.dart`.
  final String? fundingType;
  final String? fundingId;

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
    this.fundingType,
    this.fundingId,
  });

  bool get isLinked => fundingType != null && fundingId != null;
  String? get fundingKey => isLinked ? '$fundingType:$fundingId' : null;

  double get progress => target == 0 ? 0 : (current / target).clamp(0, 1);
  int get remaining => (target - current).clamp(0, target);
  bool get isComplete => current >= target;

  /// Salinan goal dengan `current` hasil hitungan dari aset (linked goals).
  Goal withCurrent(int value) => Goal(
        id: id,
        label: label,
        target: target,
        current: value,
        dueDate: dueDate,
        monthlyContrib: monthlyContrib,
        icon: icon,
        color: color,
        scope: scope,
        ownerId: ownerId,
        createdAt: createdAt,
        presetId: presetId,
        sortIndex: sortIndex,
        fundingType: fundingType,
        fundingId: fundingId,
      );

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
        if (fundingType != null) 'fundingType': fundingType,
        if (fundingId != null) 'fundingId': fundingId,
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
      fundingType: m['fundingType'] as String?,
      fundingId: m['fundingId'] as String?,
    );
  }
}

/// Pure reorder math for `ReorderableListView.onReorder`: Flutter reports
/// [newIndex] as if the moved item were still in place, so moving an item
/// down needs a −1 fix-up before insert.
List<String> reorderIds({
  required List<String> ids,
  required int oldIndex,
  required int newIndex,
}) {
  var ni = newIndex;
  if (ni > oldIndex) ni -= 1;
  final out = [...ids];
  final moved = out.removeAt(oldIndex);
  out.insert(ni, moved);
  return out;
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

/// Milestone yang baru terlewati oleh sebuah setoran: 100 (target tercapai)
/// atau 50 (setengah jalan). Null bila tidak ada yang terlewati.
/// Riset retensi: rayakan progres otomatis (Monarch/Harmoney), sekali saja
/// di momen terlewati — tanpa badge permanen.
int? goalMilestoneCrossed({
  required int before,
  required int after,
  required int target,
}) {
  if (target <= 0 || after <= before) return null;
  if (before < target && after >= target) return 100;
  if (before * 2 < target && after * 2 >= target) return 50;
  return null;
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
