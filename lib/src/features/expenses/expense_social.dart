import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'expense.dart';

/// Komentar pada satu pengeluaran. Disimpan di
/// `households/{hid}/expenses/{eid}/comments/{cid}`.
class ExpenseComment {
  final String id;
  final String authorId;
  final String text;
  final DateTime createdAt;

  const ExpenseComment({
    required this.id,
    required this.authorId,
    required this.text,
    required this.createdAt,
  });

  static ExpenseComment fromSnapshot(DocumentSnapshot snap) {
    final m = snap.data() as Map<String, dynamic>;
    return ExpenseComment(
      id: snap.id,
      authorId: m['authorId'] as String,
      text: m['text'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Komentar + reaksi emoji di transaksi. Reaksi disimpan sebagai map
/// `reactions: {<uid>: <emoji>}` di doc pengeluaran (1 reaksi per anggota);
/// komentar di subcollection `comments`.
class ExpenseSocialRepository {
  ExpenseSocialRepository(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _expense(String hid, String eid) =>
      _db
          .collection('households')
          .doc(hid)
          .collection('expenses')
          .doc(eid);

  CollectionReference<Map<String, dynamic>> _comments(
          String hid, String eid) =>
      _expense(hid, eid).collection('comments');

  Stream<List<ExpenseComment>> watchComments({
    required String householdId,
    required String expenseId,
  }) {
    return _comments(householdId, expenseId)
        .orderBy('createdAt')
        .snapshots()
        .map((s) => s.docs.map(ExpenseComment.fromSnapshot).toList());
  }

  Future<void> addComment({
    required String householdId,
    required String expenseId,
    required String authorId,
    required String text,
  }) {
    return _comments(householdId, expenseId).add({
      'authorId': authorId,
      'text': text,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteComment({
    required String householdId,
    required String expenseId,
    required String commentId,
  }) {
    return _comments(householdId, expenseId).doc(commentId).delete();
  }

  /// Tap emoji yang sama = hapus reaksi; emoji lain = ganti.
  Future<void> toggleReaction({
    required String householdId,
    required String expenseId,
    required String uid,
    required String emoji,
    required String? current,
  }) {
    return _expense(householdId, expenseId).update({
      'reactions.$uid':
          current == emoji ? FieldValue.delete() : emoji,
    });
  }

  /// Minta anggota lain meninjau transaksi (menimpa permintaan sebelumnya).
  Future<void> requestReview({
    required String householdId,
    required String expenseId,
    required String by,
    required String to,
  }) {
    return _expense(householdId, expenseId).update({
      'review': ReviewRequest(
        by: by,
        to: to,
        done: false,
        at: DateTime.now(),
      ).toMap(),
    });
  }

  Future<void> resolveReview({
    required String householdId,
    required String expenseId,
  }) {
    return _expense(householdId, expenseId).update({'review.done': true});
  }

  Future<void> clearReview({
    required String householdId,
    required String expenseId,
  }) {
    return _expense(householdId, expenseId)
        .update({'review': FieldValue.delete()});
  }
}

final expenseSocialRepositoryProvider =
    Provider<ExpenseSocialRepository>((ref) {
  return ExpenseSocialRepository(ref.watch(firestoreProvider));
});

/// Komentar live untuk satu pengeluaran.
final expenseCommentsProvider = StreamProvider.family<List<ExpenseComment>,
    ({String hid, String eid})>((ref, args) {
  return ref.watch(expenseSocialRepositoryProvider).watchComments(
        householdId: args.hid,
        expenseId: args.eid,
      );
});

/// Doc pengeluaran live — dipakai detail sheet agar reaksi langsung
/// ter-update saat anggota lain bereaksi. Null bila doc dihapus.
final expenseLiveProvider =
    StreamProvider.family<Expense?, ({String hid, String eid})>((ref, args) {
  return ref
      .watch(firestoreProvider)
      .collection('households')
      .doc(args.hid)
      .collection('expenses')
      .doc(args.eid)
      .snapshots()
      .map((s) => s.exists ? Expense.fromSnapshot(s) : null);
});
