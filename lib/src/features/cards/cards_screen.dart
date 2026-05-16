import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../household/household_providers.dart';
import 'credit_card.dart';
import 'card_repository.dart';
import 'edit_card_sheet.dart';

final cardsProvider = StreamProvider.family<List<CreditCard>, String>((ref, hid) {
  return ref.watch(cardRepositoryProvider).watchAll(hid);
});

class CardsScreen extends ConsumerWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final household = ref.watch(currentHouseholdProvider).value;
    if (household == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final cards = ref.watch(cardsProvider(household.id));
    return Scaffold(
      appBar: AppBar(title: const Text('Kartu Kredit')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddSheet(context, ref, household.id, household.members.first.userId),
        icon: const Icon(Icons.add),
        label: const Text('Tambah kartu'),
      ),
      body: cards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Belum ada kartu. Tambah lewat tombol "+".',
                    style: TextStyle(color: Colors.grey.shade600)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final c = items[i];
              final owner = household.memberOf(c.ownerId);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CardTile(
                  card: c,
                  ownerName: owner?.displayName ?? '-',
                  onTap: () =>
                      context.push('/cards/${c.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openAddSheet(
    BuildContext context,
    WidgetRef ref,
    String hid,
    String defaultOwnerId,
  ) async {
    final result = await showModalBottomSheet<CardDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EditCardSheet(defaultOwnerId: defaultOwnerId),
    );
    if (result == null) return;
    await ref.read(cardRepositoryProvider).addCard(
          hid: hid,
          ownerId: result.ownerId,
          label: result.label,
          last4: result.last4,
          limit: result.limit,
          dueDay: result.dueDay,
          apr: result.apr,
          accent: result.accent,
          minPaymentPct: result.minPaymentPct,
        );
  }
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.ownerName,
    required this.onTap,
  });
  final CreditCard card;
  final String ownerName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(card.accent);
    final pct = card.limit == 0 ? 0.0 : (card.used / card.limit).clamp(0.0, 1.0);
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(card.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                  ),
                  Text(card.last4.isNotEmpty ? '•••• ${card.last4}' : '',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 4),
              Text(ownerName,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 16),
              Text(Money.format(card.used),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 28)),
              Text('dari ${Money.format(card.limit)}',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 8),
              Text('Jatuh tempo tanggal ${card.dueDay}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

Color _parseColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return Color(int.parse('FF$h', radix: 16));
}
