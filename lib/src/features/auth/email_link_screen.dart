import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme.dart';
import 'auth_repository.dart';
import 'auth_shell.dart';

/// Passwordless sign-in via emailed magic link.
/// Two-step flow on a single screen:
///   1. Enter email → "Kirim link"
///   2. Paste the URL from the email → "Masuk"
///
/// No deep-link plumbing — user copies the link from their email and pastes
/// it back into the app. Trade-off chosen per AGENTS.md (2-5 internal users).
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
      setState(() => _error = 'Email tidak valid');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailLink(email: email);
      setState(() {
        _stage = _Stage.awaitingLink;
        _info = 'Link sudah dikirim ke $email. Buka email di device manapun, '
            'lalu copy seluruh URL dan paste di bawah.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submitLink() async {
    final link = _link.text.trim();
    final email = _email.text.trim();
    if (link.isEmpty) {
      setState(() => _error = 'Paste link dari email');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .signInWithEmailLink(email: email, link: link);
      // Router redirect takes over.
    } on FirebaseAuthException catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
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
        onPressed: _busy ? null : () => context.go('/sign-in'),
        child: Text(
          'Kembali ke login biasa',
          style: TextStyle(color: FtColors.ink3, fontSize: 13),
        ),
      ),
      children: [
        LabeledField(
          label: 'Email',
          child: TextField(
            controller: _email,
            enabled: !isStep2,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'kamu@email.com'),
          ),
        ),
        if (isStep2)
          LabeledField(
            label: 'Link dari email',
            child: TextField(
              controller: _link,
              keyboardType: TextInputType.url,
              autocorrect: false,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'https://financial-tracker-4791d...',
                suffixIcon: IconButton(
                  tooltip: 'Paste dari clipboard',
                  icon: const Icon(Icons.content_paste_outlined,
                      size: 18, color: FtColors.ink3),
                  onPressed: _busy ? null : _pasteFromClipboard,
                ),
              ),
            ),
          ),
        if (_info != null)
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: FtColors.sage.withValues(alpha: 0.08),
              border: Border.all(
                  color: FtColors.sage.withValues(alpha: 0.3), width: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.mark_email_read_outlined,
                    color: FtColors.moss, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _info!,
                    style: const TextStyle(
                      color: FtColors.moss,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (_error != null) AuthErrorBanner(message: _error!),
        FilledButton(
          onPressed: _busy
              ? null
              : (isStep2 ? _submitLink : _sendLink),
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
                : () => setState(() {
                      _stage = _Stage.compose;
                      _info = null;
                      _link.clear();
                    }),
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
