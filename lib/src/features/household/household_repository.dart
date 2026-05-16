import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ids.dart';
import '../../core/invite_code.dart';
import '../../core/providers.dart';
import '../../core/seeded_data.dart';
import 'household.dart';

class HouseholdRepository {
  HouseholdRepository(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _households =>
      _db.collection('households');
  CollectionReference<Map<String, dynamic>> get _invites =>
      _db.collection('invites');
  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');

  Stream<Household?> watch(String householdId) =>
      _households.doc(householdId).snapshots().map(
            (snap) => snap.exists ? Household.fromSnapshot(snap) : null,
          );

  Future<Household?> get(String householdId) async {
    final snap = await _households.doc(householdId).get();
    return snap.exists ? Household.fromSnapshot(snap) : null;
  }

  /// Creates a new household, seeds defaults, and links creator's user doc.
  /// Throws if the creator already belongs to a household.
  Future<String> create({
    required String creatorUid,
    required String creatorName,
    required MemberRole creatorRole,
    required String name,
    required int payday,
    required int monthlyBudgetTotal,
    required Map<String, int> categoryBudgets,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final hid = _households.doc().id;

    final categories = [
      for (var i = 0; i < seededCategories.length; i++)
        Category(
          id: seededCategories[i].id,
          label: seededCategories[i].label,
          icon: seededCategories[i].icon,
          color: seededCategories[i].color,
          monthlyBudget: categoryBudgets[seededCategories[i].id] ?? 0,
          sortOrder: i,
        ),
    ];
    final methods = [
      for (final p in seededPaymentMethods)
        PaymentMethod(id: p.id, label: p.label, type: p.type, builtIn: true),
    ];
    final creator = Member(
      userId: creatorUid,
      displayName: creatorName,
      role: creatorRole,
      color: '#B8825A',
      joinedAt: ts,
      isCreator: true,
    );
    final household = Household(
      id: hid,
      name: name,
      creatorId: creatorUid,
      createdAt: ts,
      payday: payday,
      monthlyBudgetTotal: monthlyBudgetTotal,
      memberIds: [creatorUid],
      members: [creator],
      categories: categories,
      paymentMethods: methods,
    );

    // Transaction: create household + link user.householdId atomically.
    await _db.runTransaction((tx) async {
      final userRef = _users.doc(creatorUid);
      final userSnap = await tx.get(userRef);
      final existingHid = userSnap.data()?['householdId'] as String?;
      if (existingHid != null && existingHid.isNotEmpty) {
        throw StateError('user_already_in_household');
      }
      tx.set(_households.doc(hid), household.toMap());
      tx.set(userRef, {'householdId': hid}, SetOptions(merge: true));
    });
    return hid;
  }

  /// Generates a fresh 6-digit invite code. Retries on collision (extremely
  /// unlikely; one in a million per attempt).
  Future<String> createInvite({
    required String householdId,
    required String generatedBy,
    Duration ttl = const Duration(hours: 24),
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    for (var attempt = 0; attempt < 5; attempt++) {
      final code = InviteCode.generate();
      try {
        await _invites.doc(code).set({
          'householdId': householdId,
          'generatedBy': generatedBy,
          'generatedAt': Timestamp.fromDate(ts),
          'expiresAt': Timestamp.fromDate(ts.add(ttl)),
          'consumed': false,
        });
        return code;
      } on FirebaseException catch (e) {
        // ALREADY_EXISTS is rare for 6-digit space at <100 outstanding codes.
        if (e.code != 'already-exists') rethrow;
      }
    }
    throw StateError('invite_code_collision_retries_exhausted');
  }

  /// Validates + consumes an invite, adds user as a member, and links user doc.
  /// All-or-nothing transaction. Throws on invalid/expired/consumed code.
  Future<String> joinWithInvite({
    required String code,
    required String userId,
    required String displayName,
    required MemberRole role,
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    return _db.runTransaction<String>((tx) async {
      final inviteRef = _invites.doc(code);
      final inviteSnap = await tx.get(inviteRef);
      if (!inviteSnap.exists) throw StateError('invite_not_found');
      final inv = inviteSnap.data()!;
      if (inv['consumed'] as bool? ?? false) {
        throw StateError('invite_consumed');
      }
      final expiresAt = (inv['expiresAt'] as Timestamp).toDate();
      if (ts.isAfter(expiresAt)) throw StateError('invite_expired');

      final householdId = inv['householdId'] as String;
      final householdRef = _households.doc(householdId);
      final householdSnap = await tx.get(householdRef);
      if (!householdSnap.exists) throw StateError('household_missing');

      final userRef = _users.doc(userId);
      final userSnap = await tx.get(userRef);
      final existingHid = userSnap.data()?['householdId'] as String?;
      if (existingHid != null && existingHid.isNotEmpty) {
        throw StateError('user_already_in_household');
      }

      final household = Household.fromSnapshot(householdSnap);
      if (household.memberIds.contains(userId)) {
        throw StateError('already_member');
      }

      final newMember = Member(
        userId: userId,
        displayName: displayName,
        role: role,
        color: _pickMemberColor(household.members.length),
        joinedAt: ts,
        isCreator: false,
      );
      final updatedMembers = [...household.members.map((m) => m.toMap()), newMember.toMap()];
      final updatedIds = [...household.memberIds, userId];

      tx.update(householdRef, {
        'memberIds': updatedIds,
        'members': updatedMembers,
      });
      tx.update(inviteRef, {
        'consumed': true,
        'consumedBy': userId,
        'consumedAt': Timestamp.fromDate(ts),
      });
      tx.set(userRef, {'householdId': householdId}, SetOptions(merge: true));
      return householdId;
    });
  }

  /// Removes a member from the household. If creator leaves, the next member
  /// becomes creator. If the household becomes empty, it (and the doc) is
  /// deleted along with its subcollections (caller-driven cleanup beyond MVP).
  Future<void> leave({
    required String householdId,
    required String userId,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _households.doc(householdId);
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('household_missing');
      final household = Household.fromSnapshot(snap);

      final remainingIds =
          household.memberIds.where((id) => id != userId).toList();
      final remainingMembers =
          household.members.where((m) => m.userId != userId).toList();

      if (remainingIds.isEmpty) {
        tx.delete(ref);
      } else {
        // Promote first remaining member to creator if leaver was creator.
        final wasCreator =
            household.creatorId == userId || remainingMembers.first.isCreator;
        final newMembers = wasCreator
            ? [
                Member(
                  userId: remainingMembers.first.userId,
                  displayName: remainingMembers.first.displayName,
                  role: remainingMembers.first.role,
                  color: remainingMembers.first.color,
                  joinedAt: remainingMembers.first.joinedAt,
                  isCreator: true,
                ),
                ...remainingMembers.skip(1),
              ]
            : remainingMembers;
        tx.update(ref, {
          'memberIds': remainingIds,
          'members': newMembers.map((m) => m.toMap()).toList(),
          if (wasCreator) 'creatorId': newMembers.first.userId,
        });
      }
      tx.set(
        _users.doc(userId),
        {'householdId': FieldValue.delete()},
        SetOptions(merge: true),
      );
    });
  }

  Future<void> updateCategories({
    required String householdId,
    required List<Category> categories,
  }) async {
    await _households.doc(householdId).update({
      'categories': categories.map((c) => c.toMap()).toList(),
    });
  }

  /// Adds a new user-defined category. Generates a short ID.
  Future<Category> addCategory({
    required String householdId,
    required String label,
    required String icon,
    required String color,
    required int monthlyBudget,
  }) async {
    final household = await get(householdId);
    if (household == null) throw StateError('household_missing');
    final next = Category(
      id: shortId(),
      label: label,
      icon: icon,
      color: color,
      monthlyBudget: monthlyBudget,
      sortOrder: household.categories.length,
    );
    await updateCategories(
      householdId: householdId,
      categories: [...household.categories, next],
    );
    return next;
  }

  String _pickMemberColor(int index) {
    const palette = [
      '#B8825A',
      '#10B981',
      '#3B82F6',
      '#EC4899',
      '#F59E0B',
      '#8B5CF6',
    ];
    return palette[index % palette.length];
  }
}

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(ref.watch(firestoreProvider));
});
