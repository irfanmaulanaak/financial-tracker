/// App lock: PIN 6 digit + biometrik opsional.
///
/// Default MATI — hanya aktif bila user menyalakannya dari
/// Pengaturan → Akun & Keamanan. PIN tidak pernah disimpan mentah:
/// yang disimpan SHA-256("salt:pin") di `flutter_secure_storage`
/// (iOS Keychain / Android Keystore-backed, terenkripsi oleh OS).
/// Biometrik via `local_auth`, dengan fallback kredensial perangkat.
///
/// Mobile-only: di web fitur disembunyikan (local_auth tidak tersedia).
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Panjang PIN yang dipakai di seluruh flow.
const appLockPinLength = 6;

/// Pure — hash PIN dengan salt. Diuji unit.
String hashPin(String pin, String salt) =>
    sha256.convert(utf8.encode('$salt:$pin')).toString();

/// Pure-ish — 16 byte acak (hex). [rng] injectable untuk test.
String generateSalt({Random? rng}) {
  final r = rng ?? Random.secure();
  return List<int>.generate(16, (_) => r.nextInt(256))
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
}

class AppLockState {
  const AppLockState({
    required this.loaded,
    required this.enabled,
    required this.biometric,
    required this.locked,
  });

  /// Settings sudah terbaca dari secure storage. Gate menampilkan layar
  /// kosong sampai true supaya konten tidak sempat terlihat saat cold start.
  final bool loaded;
  final bool enabled;
  final bool biometric;
  final bool locked;

  AppLockState copyWith({
    bool? loaded,
    bool? enabled,
    bool? biometric,
    bool? locked,
  }) =>
      AppLockState(
        loaded: loaded ?? this.loaded,
        enabled: enabled ?? this.enabled,
        biometric: biometric ?? this.biometric,
        locked: locked ?? this.locked,
      );
}

final appLockProvider =
    NotifierProvider<AppLockController, AppLockState>(AppLockController.new);

class AppLockController extends Notifier<AppLockState> {
  static const _kPinHash = 'app_lock_pin_hash';
  static const _kPinSalt = 'app_lock_pin_salt';
  static const _kBiometric = 'app_lock_biometric';

  static bool get supported => !kIsWeb;

  static const _storage = FlutterSecureStorage();
  final _auth = LocalAuthentication();

  /// Saat prompt biometrik tampil, app bisa kena lifecycle pause —
  /// jangan ikut mengunci ulang di tengah upaya unlock.
  bool _authInProgress = false;

  @override
  AppLockState build() {
    if (supported) {
      // ignore: discarded_futures
      _load();
      return const AppLockState(
          loaded: false, enabled: false, biometric: false, locked: false);
    }
    return const AppLockState(
        loaded: true, enabled: false, biometric: false, locked: false);
  }

  Future<void> _load() async {
    String? hash;
    String? bio;
    try {
      hash = await _storage.read(key: _kPinHash);
      bio = await _storage.read(key: _kBiometric);
    } catch (e) {
      // Storage rusak → fail open dengan log keras; user masih bisa
      // mengaktifkan ulang dari Pengaturan.
      debugPrint('app_lock: gagal baca secure storage: $e');
    }
    final enabled = hash != null && hash.isNotEmpty;
    state = AppLockState(
      loaded: true,
      enabled: enabled,
      biometric: enabled && bio == '1',
      locked: enabled,
    );
  }

  /// Nyalakan kunci dengan PIN baru. Dipanggil dari sheet setup
  /// (PIN sudah dikonfirmasi dua kali oleh UI).
  Future<void> enable(String pin) async {
    final salt = generateSalt();
    await _storage.write(key: _kPinSalt, value: salt);
    await _storage.write(key: _kPinHash, value: hashPin(pin, salt));
    await _storage.write(key: _kBiometric, value: '0');
    state = state.copyWith(enabled: true, biometric: false, locked: false);
  }

  /// Matikan kunci sepenuhnya (PIN + biometrik dihapus dari Keychain).
  Future<void> disable() async {
    await _storage.delete(key: _kPinHash);
    await _storage.delete(key: _kPinSalt);
    await _storage.delete(key: _kBiometric);
    state = state.copyWith(enabled: false, biometric: false, locked: false);
  }

  Future<void> setBiometric(bool on) async {
    await _storage.write(key: _kBiometric, value: on ? '1' : '0');
    state = state.copyWith(biometric: on);
  }

  /// Cek PIN. Benar → unlock.
  Future<bool> verifyPin(String pin) async {
    String? hash;
    String? salt;
    try {
      hash = await _storage.read(key: _kPinHash);
      salt = await _storage.read(key: _kPinSalt);
    } catch (e) {
      debugPrint('app_lock: gagal baca secure storage: $e');
      return false;
    }
    if (hash == null || salt == null) return false;
    final ok = hashPin(pin, salt) == hash;
    if (ok) state = state.copyWith(locked: false);
    return ok;
  }

  /// True bila perangkat punya biometrik / kredensial perangkat.
  Future<bool> deviceSupportsAuth() async {
    if (!supported) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('app_lock: isDeviceSupported gagal: $e');
      return false;
    }
  }

  /// Prompt biometrik (fallback ke PIN/pola perangkat). Sukses → unlock.
  /// Batal/gagal adalah kondisi yang diharapkan → false, tanpa lempar.
  Future<bool> unlockWithBiometric() async {
    if (!supported || !state.enabled || !state.biometric) return false;
    _authInProgress = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Buka kunci FinSist',
      );
      if (ok) state = state.copyWith(locked: false);
      return ok;
    } on LocalAuthException catch (e) {
      debugPrint('app_lock: biometrik gagal/batal: ${e.code}');
      return false;
    } finally {
      _authInProgress = false;
    }
  }

  /// Dipanggil gate saat app masuk background. No-op saat prompt
  /// biometrik sedang tampil.
  void lockFromLifecycle() {
    if (!state.enabled || _authInProgress) return;
    if (!state.locked) state = state.copyWith(locked: true);
  }
}
