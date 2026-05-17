import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../theme.dart';
import '../household/household_providers.dart';
import 'expense.dart';
import 'record_expense_screen.dart';

/// Loads an expense by id, then defers to [RecordExpenseScreen] in edit mode.
/// Kept as a thin shell so the router can resolve `/expenses/:id/edit`
/// without the heavy record screen knowing about Firestore lookups.
class EditExpenseScreen extends ConsumerWidget {
  const EditExpenseScreen({super.key, required this.expenseId});

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final asyncSnap = ref.watch(_expenseDocProvider((
      hid: household.id,
      id: expenseId,
    )));
    return asyncSnap.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: FtColors.bg,
        body: Center(child: Text('Gagal memuat: $e')),
      ),
      data: (snap) {
        if (!snap.exists) {
          return Scaffold(
            backgroundColor: FtColors.bg,
            body: Center(
              child: Text(
                'Pengeluaran tidak ditemukan',
                style: TextStyle(color: FtColors.ink3),
              ),
            ),
          );
        }
        return RecordExpenseScreen(initial: Expense.fromSnapshot(snap));
      },
    );
  }
}

/// One-shot fetch so the editor opens with the row state at navigation time.
/// We don't watch live updates here — concurrent edits in the same household
/// are rare for 2-5 user households.
final _expenseDocProvider = FutureProvider.family<
    DocumentSnapshot<Map<String, dynamic>>,
    ({String hid, String id})>((ref, key) {
  final db = ref.watch(firestoreProvider);
  return db
      .collection('households')
      .doc(key.hid)
      .collection('expenses')
      .doc(key.id)
      .get();
});
