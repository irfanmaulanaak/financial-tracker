/// State onboarding in-app (checklist "Mulai dari sini" + welcome sheet).
///
/// Hanya aktif untuk user yang BARU membuat / bergabung ke rumah tangga —
/// di-trigger eksplisit dari creator wizard / join screen, lalu disimpan
/// per-uid di SharedPreferences. User lama tidak pernah melewati flow itu,
/// jadi tidak pernah melihat onboarding kecuali membukanya sendiri lewat
/// menu "Panduan Mulai".
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/providers.dart';

class OnboardingUiState {
  const OnboardingUiState({
    this.checklistActive = false,
    this.welcomePending = false,
    this.budgetChecked = false,
  });

  /// Kartu checklist tampil di home.
  final bool checklistActive;

  /// Welcome sheet (anggota baru join) belum pernah ditampilkan.
  final bool welcomePending;

  /// Langkah "lihat budget" sudah di-tap (langkah manual; lainnya
  /// dihitung dari data nyata).
  final bool budgetChecked;

  OnboardingUiState copyWith({
    bool? checklistActive,
    bool? welcomePending,
    bool? budgetChecked,
  }) =>
      OnboardingUiState(
        checklistActive: checklistActive ?? this.checklistActive,
        welcomePending: welcomePending ?? this.welcomePending,
        budgetChecked: budgetChecked ?? this.budgetChecked,
      );
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingUiState>(
  OnboardingNotifier.new,
);

class OnboardingNotifier extends Notifier<OnboardingUiState> {
  String? get _uid => ref.read(authStateProvider).value?.uid;

  static String _kActive(String uid) => 'onb_active_$uid';
  static String _kWelcome(String uid) => 'onb_welcome_$uid';
  static String _kBudget(String uid) => 'onb_budget_$uid';

  @override
  OnboardingUiState build() {
    // Reload kalau user ganti akun di device yang sama.
    final uid = ref.watch(authStateProvider).value?.uid;
    if (uid != null) _load(uid);
    return const OnboardingUiState();
  }

  Future<void> _load(String uid) async {
    final p = await SharedPreferences.getInstance();
    state = OnboardingUiState(
      checklistActive: p.getBool(_kActive(uid)) ?? false,
      welcomePending: p.getBool(_kWelcome(uid)) ?? false,
      budgetChecked: p.getBool(_kBudget(uid)) ?? false,
    );
  }

  Future<void> _persist() async {
    final uid = _uid;
    if (uid == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kActive(uid), state.checklistActive);
    await p.setBool(_kWelcome(uid), state.welcomePending);
    await p.setBool(_kBudget(uid), state.budgetChecked);
  }

  /// Dipanggil saat creator selesai membuat rumah tangga.
  Future<void> startCreator() async {
    state = state.copyWith(checklistActive: true);
    await _persist();
  }

  /// Dipanggil saat anggota baru berhasil join via kode undangan.
  Future<void> startJoiner() async {
    state = state.copyWith(checklistActive: true, welcomePending: true);
    await _persist();
  }

  Future<void> markWelcomeSeen() async {
    state = state.copyWith(welcomePending: false);
    await _persist();
  }

  Future<void> markBudgetChecked() async {
    state = state.copyWith(budgetChecked: true);
    await _persist();
  }

  Future<void> dismissChecklist() async {
    state = state.copyWith(checklistActive: false);
    await _persist();
  }

  /// Dari menu "Panduan Mulai" — bisa dibuka siapa pun, kapan pun.
  Future<void> reopenChecklist() async {
    state = state.copyWith(checklistActive: true);
    await _persist();
  }
}
