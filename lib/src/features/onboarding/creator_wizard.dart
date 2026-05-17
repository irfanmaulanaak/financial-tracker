import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/formatters.dart';
import '../../core/providers.dart';
import '../../core/seeded_data.dart';
import '../../theme.dart';
import '../../ui/ft_ui.dart';
import '../household/household.dart';
import '../household/household_repository.dart';
import '../household/name_format.dart';

class CreatorWizardScreen extends ConsumerStatefulWidget {
  const CreatorWizardScreen({super.key});

  @override
  ConsumerState<CreatorWizardScreen> createState() =>
      _CreatorWizardScreenState();
}

class _CreatorWizardScreenState extends ConsumerState<CreatorWizardScreen> {
  int _step = 0;

  final _nameCtrl = TextEditingController();
  MemberRole _role = MemberRole.suami;

  final _budgetCtrl = TextEditingController();
  int _payday = 30;

  final Map<String, TextEditingController> _catBudgets = {
    for (final c in seededCategories) c.id: TextEditingController(),
  };

  bool _busy = false;
  String? _error;
  String? _createdHouseholdId;
  String? _inviteCode;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _budgetCtrl.dispose();
    for (final c in _catBudgets.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _createHousehold() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    final budget = Money.parse(_budgetCtrl.text) ?? 0;
    if (_nameCtrl.text.trim().isEmpty || budget <= 0) {
      setState(() => _error = 'Nama dan budget wajib diisi');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final categoryBudgets = <String, int>{
        for (final entry in _catBudgets.entries)
          if (Money.parse(entry.value.text) != null)
            entry.key: Money.parse(entry.value.text)!,
      };
      final hid = await ref
          .read(householdRepositoryProvider)
          .create(
            creatorUid: user.uid,
            creatorName: prettyName(user.displayName ?? user.email ?? ''),
            creatorRole: _role,
            name: _nameCtrl.text.trim(),
            payday: _payday,
            monthlyBudgetTotal: budget,
            categoryBudgets: categoryBudgets,
          );
      setState(() {
        _createdHouseholdId = hid;
        _step = 3;
      });
    } catch (e) {
      setState(() => _error = 'Gagal membuat rumah tangga: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _generateInvite() async {
    if (_createdHouseholdId == null) return;
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await ref
          .read(householdRepositoryProvider)
          .createInvite(
            householdId: _createdHouseholdId!,
            generatedBy: user.uid,
          );
      setState(() => _inviteCode = code);
    } catch (e) {
      setState(() => _error = 'Gagal membuat kode: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FtColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            FtSubHeader(
              title: 'Buat rumah tangga',
              onBack: _step == 0 || _step == 3
                  ? () => context.go(_step == 3 ? '/home' : '/landing')
                  : () => setState(() => _step--),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: switch (_step) {
                  0 => _stepName(),
                  1 => _stepBudget(),
                  2 => _stepCategories(),
                  _ => _stepInvite(),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Eyebrow('Langkah 1'),
        const SizedBox(height: 6),
        Text(
          'Nama rumah tangga',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Nama',
            hintText: 'Keluarga Akbar',
          ),
        ),
        const SizedBox(height: 24),
        Text('Peran kamu', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<MemberRole>(
          initialValue: _role,
          items: MemberRole.values
              .map(
                (r) => DropdownMenuItem(value: r, child: Text(roleToString(r))),
              )
              .toList(),
          onChanged: (v) => setState(() => _role = v ?? _role),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => setState(() => _step = 1),
          child: const Text('Lanjut'),
        ),
      ],
    );
  }

  Widget _stepBudget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Eyebrow('Langkah 2'),
        const SizedBox(height: 6),
        Text('Budget bulanan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(
          controller: _budgetCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Total budget per siklus (Rp)',
            hintText: '9000000',
          ),
        ),
        const SizedBox(height: 24),
        Text('Tanggal gajian', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: _payday.toDouble(),
                min: 1,
                max: 31,
                divisions: 30,
                label: '$_payday',
                onChanged: (v) => setState(() => _payday = v.round()),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                '$_payday',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Jika gajian jatuh di Sabtu/Minggu, akan otomatis mundur ke Jumat.',
          style: TextStyle(color: FtColors.ink3, fontSize: 12),
        ),
        const Spacer(),
        FilledButton(
          onPressed: () => setState(() => _step = 2),
          child: const Text('Lanjut'),
        ),
      ],
    );
  }

  Widget _stepCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Eyebrow('Langkah 3'),
        const SizedBox(height: 6),
        Text(
          'Kategori (opsional)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Isi budget per kategori sekarang, atau lewati dan atur nanti.',
          style: TextStyle(color: FtColors.ink3),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: seededCategories.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final c = seededCategories[i];
              return TextField(
                controller: _catBudgets[c.id],
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: c.label,
                  prefixText: 'Rp ',
                ),
              );
            },
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _busy ? null : _createHousehold,
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Buat rumah tangga'),
        ),
      ],
    );
  }

  Widget _stepInvite() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          'Rumah tangga dibuat!',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        if (_inviteCode == null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Undang anggota pertama (opsional). Kode hanya bisa dipakai sekali.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy ? null : _generateInvite,
                icon: const Icon(Icons.key),
                label: const Text('Buat kode undangan'),
              ),
            ],
          )
        else
          _InviteCodeCard(code: _inviteCode!),
        if (_error != null) ...[
          const SizedBox(height: 8),
        ],
        const Spacer(),
        FilledButton(
          onPressed: () => context.go('/home'),
          child: const Text('Selesai'),
        ),
      ],
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  const _InviteCodeCard({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return FtCard(
      backgroundColor: const Color(0xFFE9D9C8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        children: [
          const Text('Kode undangan'),
          const SizedBox(height: 8),
          SelectableText(
            code,
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
              color: FtColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          IconButton(
            tooltip: 'Salin',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Kode disalin')));
            },
            icon: const Icon(Icons.copy),
          ),
        ],
      ),
    );
  }
}
