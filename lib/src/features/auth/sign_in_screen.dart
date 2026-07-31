import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_input.dart';
import 'auth_repository.dart';
import 'auth_shell.dart';
import 'auth_legal_links.dart';
import 'google_sign_in_button.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      FtHaptics.warning();
      return;
    }
    FtHaptics.tap();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
      if (mounted) FtHaptics.success();
    } on FirebaseAuthException catch (e) {
      FtHaptics.error();
      setState(() => _error = _friendlyAuthError(e));
    } catch (e) {
      FtHaptics.error();
      setState(() => _error = 'Gagal masuk: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'Masuk',
      headline: 'Selamat datang\nkembali.',
      subtitle:
          'Catat pengeluaran, atur anggaran, pantau cicilan, dan menabung bersama keluarga.',
      quietFooter: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          Text(
            'Belum punya akun?',
            style: TextStyle(color: FtColors.ink3, fontSize: 13),
          ),
          TextButton(
            onPressed: _busy ? null : () => context.go('/sign-up'),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Daftar',
              style: TextStyle(
                color: FtColors.clay,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          if (kDebugMode)
            TextButton(
              onPressed: () => context.go('/dev/liquid'),
              child: const Text('Lab', style: TextStyle(fontSize: 13)),
            ),
        ],
      ),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FtInput(
                label: 'Email',
                controller: _email,
                hintText: 'kamu@email.com',
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Email tidak valid'
                    : null,
              ),
              const SizedBox(height: 14),
              FtInput(
                label: 'Password',
                controller: _password,
                hintText: '••••••',
                obscureText: _obscure,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                trailing: IconButton(
                  onPressed: () {
                    FtHaptics.select();
                    setState(() => _obscure = !_obscure);
                  },
                  splashRadius: 18,
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: FtColors.ink3,
                  ),
                ),
                validator: (v) => (v == null || v.length < 6)
                    ? 'Minimal 6 karakter'
                    : null,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _busy
                      ? null
                      : () {
                          FtHaptics.tap();
                          context.push('/sign-in-link');
                        },
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Lupa password?',
                    style: TextStyle(
                      color: FtColors.ink3,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_error != null) AuthErrorBanner(message: _error!),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FtColors.bg,
                  ),
                )
              : const Text('Masuk'),
        ),
        const OrDivider(),
        GoogleSignInButton(
          enabled: !_busy,
          onError: (msg) {
            FtHaptics.error();
            setState(() => _error = msg);
          },
        ),
        const SizedBox(height: 16),
        const AuthLegalLinks(),
      ],
    );
  }
}

String _friendlyAuthError(FirebaseAuthException e) => switch (e.code) {
      'invalid-email' => 'Email tidak valid',
      'user-disabled' => 'Akun dinonaktifkan',
      'user-not-found' || 'wrong-password' || 'invalid-credential' =>
        'Email atau password salah',
      'email-already-in-use' => 'Email sudah digunakan',
      'weak-password' => 'Password terlalu lemah',
      'network-request-failed' => 'Tidak ada koneksi internet',
      'configuration-not-found' || 'operation-not-allowed' =>
        'Provider belum diaktifkan di Firebase Console',
      _ => 'Gagal: ${e.message ?? e.code}',
    };
