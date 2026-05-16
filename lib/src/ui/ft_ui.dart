import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import 'ft_haptics.dart';
import 'ft_motion.dart';

class FtCard extends StatelessWidget {
  const FtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? FtColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FtColors.line, width: 0.5),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), offset: Offset(0, 1)),
        ],
      ),
      child: child,
    );

    final wrapped = onTap == null && onLongPress == null
        ? card
        : FtTapScale(
            onTap: onTap,
            onLongPress: onLongPress,
            child: card,
          );

    if (margin == null) return wrapped;
    return Padding(padding: margin!, child: wrapped);
  }
}

class FtSectionHeader extends StatelessWidget {
  const FtSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
      child: Row(
        children: [
          Expanded(child: Eyebrow(title)),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!, style: const TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class FtProgressBar extends StatelessWidget {
  const FtProgressBar({
    super.key,
    required this.value,
    required this.max,
    required this.color,
    this.height = 4,
    this.trackColor = FtColors.line,
  });

  final num value;
  final num max;
  final Color color;
  final double height;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final pct = max <= 0 ? 0.0 : (value / max).clamp(0.0, 1.0).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: height,
        backgroundColor: trackColor,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class FtStatGrid extends StatelessWidget {
  const FtStatGrid({super.key, required this.items});

  final List<FtStatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Expanded(child: items[i]),
          if (i != items.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class FtStatItem extends StatelessWidget {
  const FtStatItem({
    super.key,
    required this.label,
    required this.value,
    this.color = FtColors.ink,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FtColors.ink3,
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class FtAppChrome extends StatelessWidget {
  const FtAppChrome({
    super.key,
    required this.current,
    required this.child,
    this.showNav = true,
  });

  final FtTab current;
  final Widget child;
  final bool showNav;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        if (showNav)
          Positioned(
            left: 12,
            right: 12,
            bottom: 22,
            child: FtBottomNav(current: current),
          ),
      ],
    );
  }
}

enum FtTab { home, spend, assets, goals, cards }

class FtBottomNav extends StatelessWidget {
  const FtBottomNav({super.key, required this.current});

  final FtTab current;

  @override
  Widget build(BuildContext context) {
    final items = [
      _FtNavItem(FtTab.home, Icons.home_outlined, 'Beranda', '/home'),
      _FtNavItem(
        FtTab.spend,
        Icons.donut_large_outlined,
        'Keluar',
        '/expenses',
      ),
      _FtNavItem(
        FtTab.assets,
        Icons.account_balance_wallet_outlined,
        'Aset',
        '/accounts',
      ),
      _FtNavItem(FtTab.goals, Icons.flag_outlined, 'Tujuan', '/goals'),
      _FtNavItem(FtTab.cards, Icons.credit_card_outlined, 'Utang', '/cards'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: FtColors.surface.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: FtColors.lineStrong, width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              for (final item in items)
                Expanded(
                  child: _FtNavButton(item: item, active: current == item.tab),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FtNavButton extends StatelessWidget {
  const _FtNavButton({required this.item, required this.active});

  final _FtNavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.94,
      haptic: false,
      onTap: active
          ? null
          : () {
              FtHaptics.select();
              context.go(item.path);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? FtColors.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: active ? FtColors.ink : FtColors.ink3,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? FtColors.ink : FtColors.ink3,
                fontSize: 9.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FtNavItem {
  const _FtNavItem(this.tab, this.icon, this.label, this.path);

  final FtTab tab;
  final IconData icon;
  final String label;
  final String path;
}

class FtSubHeader extends StatelessWidget {
  const FtSubHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed:
                onBack ??
                () {
                  if (Navigator.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
            icon: const Icon(Icons.arrow_back, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
