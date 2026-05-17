part of 'household_repository.dart';

/// Member moderation operations on `HouseholdRepository`. Split into a part
/// file so `household_repository.dart` stays under the AGENTS.md LOC budget.
extension MemberManagement on HouseholdRepository {
  /// Creator-only: removes another member from the household.
  ///
  /// The removed user's `users/{uid}.householdId` is NOT cleaned up here —
  /// rules only allow the user themselves to write that doc. The orphan is
  /// healed by `orphanedMembershipCleanupProvider` on the removed user's
  /// next session: it detects "household loaded but I'm not in members[]"
  /// and clears their `householdId`, sending them back to onboarding.
  ///
  /// Throws if [actorUid] isn't the creator, if [memberUid] is the creator
  /// itself, or if the household/member can't be found.
  Future<void> removeMember({
    required String householdId,
    required String actorUid,
    required String memberUid,
  }) async {
    final ref = _households.doc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('household_missing');
      final h = Household.fromSnapshot(snap);
      if (h.creatorId != actorUid) throw StateError('not_creator');
      if (h.creatorId == memberUid) throw StateError('cannot_remove_creator');
      final target = h.memberOf(memberUid);
      if (target == null) throw StateError('member_missing');

      final ids = h.memberIds.where((id) => id != memberUid).toList();
      final members = h.members.where((m) => m.userId != memberUid).toList();
      tx.update(ref, {
        'memberIds': ids,
        'members': members.map((m) => m.toMap()).toList(),
        'memberAccess': Household.memberAccessMap(members),
      });
    });
  }

  /// Updates a member's access level (creator-only).
  Future<void> updateMemberAccess({
    required String householdId,
    required String actorUid,
    required String memberUid,
    required AccessLevel accessLevel,
  }) async {
    final ref = _households.doc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('household_missing');
      final h = Household.fromSnapshot(snap);
      if (h.creatorId != actorUid) throw StateError('not_creator');
      final updated = [
        for (final m in h.members)
          if (m.userId == memberUid)
            Member(
              userId: m.userId,
              displayName: m.displayName,
              role: m.role,
              color: m.color,
              joinedAt: m.joinedAt,
              isCreator: m.isCreator,
              accessLevel: accessLevel,
            )
          else
            m,
      ];
      tx.update(ref, {
        'members': updated.map((m) => m.toMap()).toList(),
        'memberAccess': Household.memberAccessMap(updated),
      });
    });
  }

  /// Updates the caller's own profile fields on the household document
  /// (display name + accent color). Used by /profile/edit.
  Future<void> updateMyProfile({
    required String householdId,
    required String userId,
    String? displayName,
    String? color,
  }) async {
    final ref = _households.doc(householdId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('household_missing');
      final h = Household.fromSnapshot(snap);
      final updated = [
        for (final m in h.members)
          if (m.userId == userId)
            Member(
              userId: m.userId,
              displayName: displayName ?? m.displayName,
              role: m.role,
              color: color ?? m.color,
              joinedAt: m.joinedAt,
              isCreator: m.isCreator,
              accessLevel: m.accessLevel,
            )
          else
            m,
      ];
      tx.update(ref, {
        'members': updated.map((m) => m.toMap()).toList(),
      });
    });
  }
}
