import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_input.dart';
import 'auth_repository.dart';
import 'auth_shell.dart';
import 'google_sign_in_button.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
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
      await ref.read(authRepositoryProvider).signUp(
            email: _email.text.trim(),
            password: _password.text,
            displayName: _name.text.trim(),
          );
      if (mounted) FtHaptics.success();
    } on FirebaseAuthException catch (e) {
      FtHaptics.error();
      setState(() => _error = _friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'Daftar',
      headline: 'Atur keuangan,\nbersama keluarga.',
      subtitle:
          'Buat akun untuk mulai mencatat pengeluaran, tabungan, dan tujuan.',
      quietFooter: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          const Text(
            'Sudah punya akun?',
            style: TextStyle(color: FtColors.ink3, fontSize: 13),
          ),
          TextButton(
            onPressed: _busy ? null : () => context.go('/sign-in'),
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Masuk',
              style: TextStyle(
                color: FtColors.clay,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
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
                label: 'Nama panggilan',
                controller: _name,
                hintText: 'Mis. Irfan',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
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
                hintText: 'Minimal 6 karakter',
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
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Minimal 6 karakter' : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        if (_error != null) AuthErrorBanner(message: _error!),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FtColors.bg,
                  ),
                )
              : const Text('Buat akun'),
        ),
        const OrDivider(),
        GoogleSignInButton(
          enabled: !_busy,
          onError: (msg) {
            FtHaptics.error();
            setState(() => _error = msg);
          },
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _busy
              ? null
              : () {
                  FtHaptics.tap();
                  context.push('/sign-in-link');
                },
          icon: const Icon(Icons.link, size: 18, color: FtColors.ink2),
          label: const Text('Daftar lewat link email'),
        ),
        const SizedBox(height: 18),
        const Text(
          'Dengan mendaftar, kamu menyetujui penggunaan data sesuai kebijakan internal aplikasi.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: FtColors.ink4,
            fontSize: 11,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

String _friendlyAuthError(FirebaseAuthException e) => switch (e.code) {
      'invalid-email' => 'Email tidak valid',
      'email-already-in-use' => 'Email sudah digunakan',
      'weak-password' => 'Password terlalu lemah',
      'network-request-failed' => 'Tidak ada koneksi internet',
      'configuration-not-found' || 'operation-not-allowed' =>
        'Provider Email/Password belum diaktifkan di Firebase Console',
      _ => 'Gagal: ${e.message ?? e.code}',
    };
