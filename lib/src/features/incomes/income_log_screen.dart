import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../household/household_providers.dart';
import 'income.dart';
import 'income_repository.dart';

final _incomesProvider =
    StreamProvider.family<List<Income>, String>((ref, hid) {
  return ref.watch(incomeRepositoryProvider).watchRecent(hid: hid, limit: 100);
});

class IncomeLogScreen extends ConsumerWidget {
  const IncomeLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final incomes = ref.watch(_incomesProvider(household.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Pemasukan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/incomes/new'),
        icon: const Icon(Icons.add),
        label: const Text('Catat'),
      ),
      body: incomes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Belum ada pemasukan.',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 96),
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final inc = items[i];
              final dest = household.accountOf(inc.destinationAccountId);
              final spender = household.memberOf(inc.receivedBy);
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0x1A10B981),
                  child: Icon(Icons.arrow_downward, color: Color(0xFF10B981)),
                ),
                title: Text(incomeSourceLabel(inc.source)),
                subtitle: Text([
                  Dates.short(inc.date),
                  if (dest != null) dest.label,
                  if (spender != null) spender.displayName,
                  if (inc.note != null && inc.note!.isNotEmpty) inc.note!,
                ].join(' • ')),
                trailing: Text(
                  Money.format(inc.amount),
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onLongPress: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Hapus pemasukan?'),
                      content: const Text(
                          'Saldo akun tidak akan otomatis dikurangi. Sesuaikan manual lewat menu Akun.'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal')),
                        FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Hapus')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ref.read(incomeRepositoryProvider).delete(
                          householdId: household.id,
                          incomeId: inc.id,
                        );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
