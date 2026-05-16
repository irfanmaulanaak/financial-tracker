import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import '../../ui/ft_haptics.dart';
import '../../ui/ft_input.dart';
import 'auth_repository.dart';
import 'auth_shell.dart';

/// Passwordless sign-in via emailed magic link.
/// User receives the link in their email, copies the URL, and pastes it back.
/// No deep-link plumbing — chosen per AGENTS.md (2-5 internal users).
class EmailLinkScreen extends ConsumerStatefulWidget {
  const EmailLinkScreen({super.key});

  @override
  ConsumerState<EmailLinkScreen> createState() => _EmailLinkScreenState();
}

enum _Stage { compose, awaitingLink }

class _EmailLinkScreenState extends ConsumerState<EmailLinkScreen> {
  final _email = TextEditingController();
  final _link = TextEditingController();
  _Stage _stage = _Stage.compose;
  bool _busy = false;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _email.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      FtHaptics.warning();
      setState(() => _error = 'Email tidak valid');
      return;
    }
    FtHaptics.tap();
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailLink(email: email);
      if (mounted) FtHaptics.success();
      setState(() {
        _stage = _Stage.awaitingLink;
        _info = 'Link sudah dikirim ke $email. Buka email di device manapun, '
            'lalu copy seluruh URL dan paste di bawah.';
      });
    } on FirebaseAuthException catch (e) {
      FtHaptics.error();
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitLink() async {
    final link = _link.text.trim();
    final email = _email.text.trim();
    if (link.isEmpty) {
      FtHaptics.warning();
      setState(() => _error = 'Paste link dari email');
      return;
    }
    FtHaptics.tap();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmailLink(email: email, link: link);
      if (mounted) FtHaptics.success();
    } on FirebaseAuthException catch (e) {
      FtHaptics.error();
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    FtHaptics.select();
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text != null && text.isNotEmpty) {
      setState(() => _link.text = text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStep2 = _stage == _Stage.awaitingLink;
    return AuthShell(
      eyebrow: 'Masuk tanpa password',
      headline: isStep2 ? 'Cek email kamu.' : 'Pakai link\ndari email.',
      subtitle: isStep2
          ? 'Klik link di email untuk membukanya, lalu paste URL-nya di sini.'
          : 'Kami kirimkan link sekali pakai. Tidak perlu ingat password.',
      quietFooter: TextButton(
        onPressed: _busy
            ? null
            : () {
                FtHaptics.tap();
                context.go('/sign-in');
              },
        child: const Text(
          'Kembali ke login biasa',
          style: TextStyle(color: FtColors.ink3, fontSize: 13),
        ),
      ),
      children: [
        FtInput(
          label: 'Email',
          controller: _email,
          hintText: 'kamu@email.com',
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enabled: !isStep2,
        ),
        if (isStep2) ...[
          const SizedBox(height: 14),
          FtInput(
            label: 'Link dari email',
            controller: _link,
            hintText: 'https://financial-tracker-4791d...',
            keyboardType: TextInputType.url,
            autocorrect: false,
            minLines: 2,
            maxLines: 3,
            trailing: IconButton(
              onPressed: _busy ? null : _pasteFromClipboard,
              splashRadius: 18,
              icon: const Icon(
                Icons.content_paste_outlined,
                size: 18,
                color: FtColors.ink3,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        if (_info != null) AuthInfoBanner(message: _info!),
        if (_error != null) AuthErrorBanner(message: _error!),
        FilledButton(
          onPressed: _busy ? null : (isStep2 ? _submitLink : _sendLink),
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: FtColors.bg,
                  ),
                )
              : Text(isStep2 ? 'Masuk' : 'Kirim link'),
        ),
        if (isStep2) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () {
                    FtHaptics.tap();
                    setState(() {
                      _stage = _Stage.compose;
                      _info = null;
                      _link.clear();
                    });
                  },
            child: const Text('Pakai email lain'),
          ),
        ],
      ],
    );
  }
}

String _friendly(FirebaseAuthException e) => switch (e.code) {
      'invalid-email' => 'Email tidak valid',
      'user-disabled' => 'Akun dinonaktifkan',
      'invalid-action-code' || 'expired-action-code' =>
        'Link tidak valid atau sudah kedaluwarsa. Minta link baru.',
      'network-request-failed' => 'Tidak ada koneksi internet',
      'configuration-not-found' || 'operation-not-allowed' =>
        'Provider Email Link belum diaktifkan di Firebase Console',
      _ => 'Gagal: ${e.message ?? e.code}',
    };
