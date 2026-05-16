import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../household/household_providers.dart';
import 'income.dart';
import 'income_repository.dart';

class RecordIncomeScreen extends ConsumerStatefulWidget {
  const RecordIncomeScreen({super.key});

  @override
  ConsumerState<RecordIncomeScreen> createState() => _RecordIncomeScreenState();
}

class _RecordIncomeScreenState extends ConsumerState<RecordIncomeScreen> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  IncomeSource _source = IncomeSource.salary;
  String? _destinationAccountId;
  String? _receivedBy;
  DateTime _date = DateTime.now();
  bool _recurring = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    final household = ref.read(currentHouseholdProvider).value;
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (household == null || user == null) return;
    final amount = Money.parse(_amount.text);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Nominal tidak valid');
      return;
    }
    if (_destinationAccountId == null) {
      setState(() => _error = 'Pilih akun tujuan');
      return;
    }
    if (_receivedBy == null) {
      setState(() => _error = 'Pilih penerima');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(incomeRepositoryProvider).add(
            householdId: household.id,
            amount: amount,
            source: _source,
            destinationAccountId: _destinationAccountId!,
            receivedBy: _receivedBy!,
            date: _date,
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
            recurring: _recurring,
          );
      if (mounted) context.pop();
    } on StateError catch (e) {
      setState(() => _error = 'Gagal: ${e.message}');
    } catch (e) {
      setState(() => _error = 'Gagal: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final household = ref.watch(currentHouseholdProvider).value;
    final user = ref.watch(authStateProvider).value;
    if (household == null || user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    _receivedBy ??= user.uid;
    final accounts = [
      ...household.cashAccounts.map((a) => (a.id, '${a.label} (tunai/debit)')),
      ...household.savingsAccounts.map((a) => (a.id, '${a.label} (tabungan)')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Catat pemasukan')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
              ),
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<IncomeSource>(
              initialValue: _source,
              decoration: const InputDecoration(labelText: 'Sumber'),
              items: IncomeSource.values
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(incomeSourceLabel(s)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _source = v ?? _source),
            ),
            const SizedBox(height: 12),
            if (accounts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  'Belum ada akun. Buat akun lewat menu Akun dulu.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _destinationAccountId,
                decoration:
                    const InputDecoration(labelText: 'Masuk ke akun'),
                items: accounts
                    .map((a) => DropdownMenuItem(
                          value: a.$1,
                          child: Text(a.$2),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _destinationAccountId = v),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _receivedBy,
              decoration: const InputDecoration(labelText: 'Diterima oleh'),
              items: household.members
                  .map((m) => DropdownMenuItem(
                        value: m.userId,
                        child: Text(m.displayName),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _receivedBy = v),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Tanggal'),
                child: Text(Dates.short(_date)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Pemasukan berulang'),
              value: _recurring,
              onChanged: (v) => setState(() => _recurring = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
