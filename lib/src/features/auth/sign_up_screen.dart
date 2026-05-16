import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
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
    if (!_formKey.currentState!.validate()) return;
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
    } on FirebaseAuthException catch (e) {
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
            child: Text(
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
              LabeledField(
                label: 'Nama panggilan',
                child: TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'Mis. Irfan'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Wajib diisi'
                      : null,
                ),
              ),
              LabeledField(
                label: 'Email',
                child: TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(hintText: 'kamu@email.com'),
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Email tidak valid'
                      : null,
                ),
              ),
              LabeledField(
                label: 'Password',
                child: TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: 'Minimal 6 karakter',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        size: 18,
                        color: FtColors.ink3,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Minimal 6 karakter'
                      : null,
                ),
              ),
            ],
          ),
        ),
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
          onError: (msg) => setState(() => _error = msg),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Dengan mendaftar, kamu menyetujui penggunaan data sesuai kebijakan internal aplikasi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FtColors.ink4,
              fontSize: 11,
              height: 1.5,
            ),
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
