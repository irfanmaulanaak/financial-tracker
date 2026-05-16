import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household_providers.dart';
import 'income.dart';
import 'income_repository.dart';

final _incomesProvider = StreamProvider.family<List<Income>, String>((
  ref,
  hid,
) {
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
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: FtAppChrome(
          current: FtTab.assets,
          child: Column(
            children: [
              FtSubHeader(
                title: 'Pemasukan',
                trailing: IconButton.filled(
                  tooltip: 'Catat pemasukan',
                  onPressed: () => context.push('/incomes/new'),
                  icon: const Icon(Icons.add, size: 18),
                ),
              ),
              Expanded(
                child: incomes.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('Gagal: $e')),
                  data: (items) {
                    if (items.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'Belum ada pemasukan.',
                            style: TextStyle(color: FtColors.ink3),
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 112),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final inc = items[i];
                        final dest = household.accountOf(
                          inc.destinationAccountId,
                        );
                        final spender = household.memberOf(inc.receivedBy);
                        return FtCard(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          padding: const EdgeInsets.all(14),
                          onLongPress: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Hapus pemasukan?'),
                                content: const Text(
                                  'Saldo akun tujuan akan otomatis dikurangi sebesar pemasukan ini.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('Batal'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('Hapus'),
                                  ),
                                ],
                              ),
                            );
                            if (ok == true) {
                              await ref
                                  .read(incomeRepositoryProvider)
                                  .delete(
                                    householdId: household.id,
                                    incomeId: inc.id,
                                  );
                            }
                          },
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: Color(0x1A5E7A64),
                                child: Icon(
                                  Icons.arrow_downward,
                                  color: FtColors.sage,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      incomeSourceLabel(inc.source),
                                      style: const TextStyle(
                                        color: FtColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      [
                                        Dates.short(inc.date),
                                        if (dest != null) dest.label,
                                        if (spender != null)
                                          spender.displayName,
                                        if (inc.note != null &&
                                            inc.note!.isNotEmpty)
                                          inc.note!,
                                      ].join(' • '),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: FtColors.ink3,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                Money.format(inc.amount),
                                style: const TextStyle(
                                  color: FtColors.sage,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
