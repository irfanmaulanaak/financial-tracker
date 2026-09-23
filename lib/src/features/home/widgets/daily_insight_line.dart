import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../theme.dart';

const _kDayKey = 'insight_day';
const _kTextKey = 'insight_text';

/// Satu kalimat insight di home. Kalimat pertama yang dihitung hari itu
/// di-cache (SharedPreferences) supaya tidak berganti-ganti sepanjang hari —
/// maks 1 insight/hari sesuai riset anti-cerewet.
class DailyInsightLine extends StatefulWidget {
  const DailyInsightLine({super.key, required this.candidate});

  /// Kalimat hasil [dailyInsight] dari data terkini (boleh null).
  final String? candidate;

  @override
  State<DailyInsightLine> createState() => _DailyInsightLineState();
}

class _DailyInsightLineState extends State<DailyInsightLine> {
  String? _text;
  bool _resolved = false;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _resolve();
  }

  @override
  void didUpdateWidget(DailyInsightLine old) {
    super.didUpdateWidget(old);
    // Data home sering datang menyusul; coba kunci insight begitu kandidat
    // pertama muncul (selama hari ini belum terkunci).
    if (!_resolved || (_text == null && widget.candidate != null)) {
      // ignore: discarded_futures
      _resolve();
    }
  }

  Future<void> _resolve() async {
    final p = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    if (p.getString(_kDayKey) == today) {
      final stored = p.getString(_kTextKey);
      if (!mounted) return;
      setState(() {
        _resolved = true;
        _text = (stored == null || stored.isEmpty) ? null : stored;
      });
      // Hari ini belum punya insight tersimpan tapi kandidat baru muncul —
      // kunci sekarang.
      if (_text == null && widget.candidate != null) {
        await p.setString(_kTextKey, widget.candidate!);
        if (mounted) setState(() => _text = widget.candidate);
      }
      return;
    }
    // Hari baru: kunci kandidat saat ini (boleh kosong, diisi menyusul).
    await p.setString(_kDayKey, today);
    await p.setString(_kTextKey, widget.candidate ?? '');
    if (!mounted) return;
    setState(() {
      _resolved = true;
      _text = widget.candidate;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    if (text == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 0, 22, 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
      decoration: BoxDecoration(
        color: FtColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: FtColors.tileFor(FtColors.catTransport),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.lightbulb_outline_rounded,
                size: 18, color: FtColors.sage),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 13.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
