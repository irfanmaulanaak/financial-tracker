import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../theme.dart';
import '../../../ui/ft_ui.dart';
import '../../home/widgets/home_formatters.dart';
import '../account.dart';

class AccountTabRow extends StatelessWidget {
  const AccountTabRow({
    super.key,
    required this.account,
    required this.accent,
    required this.onTap,
    required this.onLongPress,
    this.hidden = false,
  });
  final Account account;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final iconData = account.kind == AccountKind.cash &&
            account.subKind == AccountSubKind.ewallet
        ? Icons.account_balance_wallet_rounded
        : Icons.account_balance_rounded;
    return FtTapScale(
      scale: 0.98,
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: accent.withValues(alpha: 0.24), width: 0.5),
              ),
              child: Icon(
                iconData,
                size: 16,
                color: accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (account.hint != null && account.hint!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      account.hint!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FtColors.ink3,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              hidden ? maskMoney() : Money.format(account.value),
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded, size: 16, color: FtColors.ink4),
          ],
        ),
      ),
    );
  }
}
