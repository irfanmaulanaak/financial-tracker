import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../ui/ft_motion.dart';

/// Bottom-anchored 12-key numeric keypad used by record-expense and
/// record-income screens. Keys are "1".."9", "000", "0", "←" (backspace).
/// Hides automatically when the soft keyboard is up so a note field can use
/// the system keyboard without competing chrome.
class RecordKeypad extends StatelessWidget {
  const RecordKeypad({super.key, required this.onTap});

  final ValueChanged<String> onTap;

  static const _keys = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '000', '0', '←',
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    if (bottomInset > 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
      decoration: BoxDecoration(
        color: FtColors.surfaceAlt,
        border: Border(top: BorderSide(color: FtColors.line, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.0,
          children: [
            for (final k in _keys)
              FtTapScale(
                scale: 0.94,
                haptic: false,
                onTap: () => onTap(k),
                child: Container(
                  decoration: BoxDecoration(
                    color: FtColors.surface,
                    border: Border.all(color: FtColors.line, width: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    k,
                    style: TextStyle(
                      fontFamily: 'Newsreader',
                      fontSize: 22,
                      fontWeight: FontWeight.w400,
                      color: FtColors.ink,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Pure key-handling logic shared by callers — appends digits/zeros or
/// backspaces. Returns the updated amount (clamped to 0..999_999_999).
int applyRecordKey(int amount, String key) {
  if (key == '←') return amount ~/ 10;
  if (key == '000') return (amount * 1000).clamp(0, 999999999);
  return (amount * 10 + int.parse(key)).clamp(0, 999999999);
}
