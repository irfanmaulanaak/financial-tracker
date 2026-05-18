import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ids.dart';
import '../../core/invite_code.dart';
import '../../core/providers.dart';
import '../../core/seeded_data.dart';
import '../accounts/household_balances.dart';
import 'household.dart';

part 'member_management.dart';

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
    );

    // Transaction: create household + balances doc + link user.householdId
    // atomically. Balances live at `private/balances` (SEC-004) so the
    // limited tier cannot read account values.
    final balancesRef = HouseholdBalances.ref(_db, hid);
    await _db.runTransaction((tx) async {
      final userRef = _users.doc(creatorUid);
      final userSnap = await tx.get(userRef);
      final existingHid = userSnap.data()?['householdId'] as String?;
      if (existingHid != null && existingHid.isNotEmpty) {
        throw StateError('user_already_in_household');
      }
      tx.set(_households.doc(hid), household.toMap());
      tx.set(balancesRef, HouseholdBalances.empty.toMap());
      tx.set(userRef, {'householdId': hid}, SetOptions(merge: true));
    });
    return hid;
  }

  /// Generates a fresh 128-bit invite token. Collision space is 2^128, so a
  /// single attempt is enough in practice; one retry is kept for paranoia.
  ///
  /// `role` and `accessLevel` are baked into the invite and applied at join
  /// time — the inviter chooses how the new member gets onboarded.
  ///
  /// Preview fields (`householdName`, `inviterDisplayName`) live on the
  /// invite doc so a non-member joiner can show context WITHOUT reading the
  /// household root (which is members-only — see firestore.rules).
  Future<String> createInvite({
    required String householdId,
    required String generatedBy,
    MemberRole role = MemberRole.other,
    AccessLevel accessLevel = AccessLevel.limited,
    Duration ttl = const Duration(hours: 24),
    DateTime? now,
  }) async {
    final ts = now ?? DateTime.now();
    final household = await get(householdId);
    if (household == null) throw StateError('household_missing');
    final inviter = household.memberOf(generatedBy);
    final inviterName = inviter?.displayName ?? '';
    for (var attempt = 0; attempt < 2; attempt++) {
      final code = InviteCode.generate();
      try {
        await _invites.doc(code).set({
          'householdId': householdId,
          'householdName': household.name,
          'inviterDisplayName': inviterName,
          'generatedBy': generatedBy,
          'generatedAt': Timestamp.fromDate(ts),
          'expiresAt': Timestamp.fromDate(ts.add(ttl)),
          'consumed': false,
          'role': roleToString(role),
          'accessLevel': accessLevelToString(accessLevel),
        });
        return code;
      } on FirebaseException catch (e) {
        if (e.code != 'already-exists') rethrow;
      }
    }
    throw StateError('invite_code_collision_retries_exhausted');
  }

  /// Validates + consumes an invite, adds user as a member, and links user
  /// doc. All-or-nothing transaction. Throws on invalid/expired/consumed code.
  ///
  /// Role + access level come from the invite doc (set by the inviter). The
  /// joiner can override `role` to fix the label for themselves; access level
  /// is always taken from the invite (joiner cannot escalate).
  ///
  /// Does NOT read the household root — that doc is members-only. The join
  /// uses `arrayUnion` + map-dot updates so it works for a non-member, and
  /// the Firestore rule shape-checks the result (see firestore.rules →
  /// "Non-member self-join").
  Future<String> joinWithInvite({
    required String code,
    required String userId,
    required String displayName,
    MemberRole? role,
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

      final userRef = _users.doc(userId);
      final userSnap = await tx.get(userRef);
      final existingHid = userSnap.data()?['householdId'] as String?;
      if (existingHid != null && existingHid.isNotEmpty) {
        throw StateError('user_already_in_household');
      }

      final inviteRole = roleFromString(inv['role'] as String?);
      final inviteAccess =
          accessLevelFromString(inv['accessLevel'] as String?);
      final inviteAccessStr = accessLevelToString(inviteAccess);

      final newMember = Member(
        userId: userId,
        displayName: displayName,
        role: role ?? inviteRole,
        color: _pickMemberColorByUid(userId),
        joinedAt: ts,
        isCreator: false,
        accessLevel: inviteAccess,
      );

      tx.update(householdRef, {
        'memberIds': FieldValue.arrayUnion([userId]),
        'members': FieldValue.arrayUnion([newMember.toMap()]),
        'memberAccess.$userId': inviteAccessStr,
        // Required by Firestore rules to prove a valid invite was claimed
        // (see `firestore.rules` → households self-join rule).
        'claimedInvite': code,
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
  /// becomes creator. If the household becomes empty, the household + all
  /// its subcollections (expenses, incomes, cards + nested installments,
  /// goals, investments) are deleted.
  Future<void> leave({
    required String householdId,
    required String userId,
  }) async {
    final ref = _households.doc(householdId);

    // Read membership outside the transaction first so we can decide whether
    // we need the subcollection cascade (which cannot run inside a single
    // transaction — see _purgeSubcollections).
    final initial = await ref.get();
    if (!initial.exists) throw StateError('household_missing');
    final household = Household.fromSnapshot(initial);
    final remainingIds =
        household.memberIds.where((id) => id != userId).toList();
    final isLastLeaver = remainingIds.isEmpty;

    if (isLastLeaver) {
      // Purge subcollections BEFORE deleting the root doc. Rules grant
      // member-only access via the root doc; once it's gone, the orphaned
      // children would be unreachable from the client.
      await _purgeSubcollections(householdId);
    }

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('household_missing');
      final h = Household.fromSnapshot(snap);
      final ids = h.memberIds.where((id) => id != userId).toList();
      final members = h.members.where((m) => m.userId != userId).toList();

      if (ids.isEmpty) {
        tx.delete(ref);
      } else {
        // Promote first remaining member to creator if leaver was creator.
        final wasCreator =
            h.creatorId == userId || members.first.isCreator;
        final newMembers = wasCreator
            ? [
                Member(
                  userId: members.first.userId,
                  displayName: members.first.displayName,
                  role: members.first.role,
                  color: members.first.color,
                  joinedAt: members.first.joinedAt,
                  isCreator: true,
                  // Promoted creator must have full access.
                  accessLevel: AccessLevel.full,
                ),
                ...members.skip(1),
              ]
            : members;
        tx.update(ref, {
          'memberIds': ids,
          'members': newMembers.map((m) => m.toMap()).toList(),
          'memberAccess': Household.memberAccessMap(newMembers),
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

  /// Deletes every doc in the household's subcollections. Batched (≤500
  /// writes per commit). Called only on last-member leave so the household
  /// disappears completely instead of leaving orphaned children.
  Future<void> _purgeSubcollections(String householdId) async {
    final root = _households.doc(householdId);
    const flatSubs = ['expenses', 'incomes', 'goals', 'investments'];
    for (final sub in flatSubs) {
      await _deleteAllDocs(root.collection(sub));
    }
    // Cards have a nested `installments` subcollection; clear those first.
    final cards = await root.collection('cards').get();
    for (final card in cards.docs) {
      await _deleteAllDocs(card.reference.collection('installments'));
    }
    await _deleteAllDocs(root.collection('cards'));
  }

  Future<void> _deleteAllDocs(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    while (true) {
      final snap = await col.limit(400).get();
      if (snap.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      if (snap.docs.length < 400) return;
    }
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

  /// Color picker that does NOT need to know the existing member count
  /// (joiner cannot read the household root). Deterministic per uid so the
  /// same user keeps the same color across rejoins.
  String _pickMemberColorByUid(String uid) {
    var hash = 0;
    for (var i = 0; i < uid.length; i++) {
      hash = (hash * 31 + uid.codeUnitAt(i)) & 0x7fffffff;
    }
    // Reserve palette[0] for creator; non-creator joiners use palette[1..].
    const palette = [
      '#10B981',
      '#3B82F6',
      '#EC4899',
      '#F59E0B',
      '#8B5CF6',
    ];
    return palette[hash % palette.length];
  }
}

final householdRepositoryProvider = Provider<HouseholdRepository>((ref) {
  return HouseholdRepository(ref.watch(firestoreProvider));
});
