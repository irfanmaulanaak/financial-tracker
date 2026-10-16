import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/household/household_providers.dart';
import '../theme.dart';
import 'ft_action_sheet.dart';
import 'ft_haptics.dart';
import 'ft_ui.dart';

/// Whether the current member may record anything (hides "+" for view-only).
bool canRecordNav(WidgetRef ref) =>
    ref.watch(canRecordTxnProvider) || ref.watch(canWriteAllProvider);

/// Shared tab list for both [FtBottomNav] (floating) and [FtFixedBottomNav]
/// (fixed) — same destinations, different chrome.
const ftNavItems = [
  _FtNavItem(
    FtTab.home,
    Icons.home_rounded,
    Icons.home_outlined,
    'Beranda',
    '/home',
  ),
  _FtNavItem(
    FtTab.spend,
    Icons.donut_large_rounded,
    Icons.donut_large_outlined,
    'Pengeluaran',
    '/spend',
  ),
  _FtNavItem(
    FtTab.cards,
    Icons.credit_card_rounded,
    Icons.credit_card_outlined,
    'Utang',
    '/cards',
  ),
  _FtNavItem(
    FtTab.assets,
    Icons.pie_chart_rounded,
    Icons.pie_chart_outline_rounded,
    'Aset',
    '/accounts',
  ),
];

/// Floating pill bottom nav ("Melayang" — opt-in): 4 tabs with the record
/// button in the middle. The active tab grows into a chip with icon +
/// label; the others are icon-only.
class FtBottomNav extends ConsumerWidget {
  const FtBottomNav({super.key, required this.current, this.showAction = true});

  final FtTab current;

  /// Show the "+" record button inside the pill.
  final bool showAction;

  static const _items = ftNavItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = showAction && canRecordNav(ref);
    // Tujuan lives behind the Aset tab (Aset | Tujuan switch).
    final effective = current == FtTab.goals ? FtTab.assets : current;
    Widget side(List<_FtNavItem> items) => Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final item in items)
            if (item.tab == effective)
              // May shrink (label scales down) on narrow phones or with
              // large text, instead of overflowing the pill.
              Flexible(child: _FtNavButton(item: item, active: true))
            else
              _FtNavButton(item: item, active: false),
        ],
      ),
    );

    return FtGlass(
      borderRadius: BorderRadius.circular(32),
      baseColor: FtColors.navBar,
      fallbackBorderColor: FtColors.line,
      boxShadow: [
        BoxShadow(
          color: FtColors.navActiveInk.withValues(alpha: 0.18),
          blurRadius: 26,
          offset: const Offset(0, 10),
        ),
      ],
      padding: const EdgeInsets.all(8),
      sweep: true,
      child: SizedBox(
        height: 48,
        // Two tabs each side of the "+"; the "+" stays dead centre and the
        // active chip only takes space from its own side.
        child: Row(
          children: [
            side(_items.sublist(0, 2)),
            if (action) const _NavRecordButton(),
            side(_items.sublist(2)),
          ],
        ),
      ),
    );
  }
}

class _NavRecordButton extends StatelessWidget {
  const _NavRecordButton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Catat aktivitas',
      child: FtTapScale(
        scale: 0.88,
        onTap: () => ActionChooserSheet.show(context),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: FtColors.fab,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.add_rounded, size: 26, color: FtColors.onFab),
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
    final color = active ? FtColors.navActiveInk : FtColors.navIcon;
    final icon = Icon(
      active ? item.iconActive : item.icon,
      size: 20,
      color: color,
    );
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: FtTapScale(
        scale: 0.92,
        haptic: false,
        onTap: active
            ? null
            : () {
                FtHaptics.select();
                context.go(item.path);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: active ? null : 42,
          height: 48,
          padding: active
              ? const EdgeInsets.symmetric(horizontal: 12)
              : EdgeInsets.zero,
          decoration: BoxDecoration(
            color: active ? FtColors.navActive : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          // Small phones (< 360 wide): icon only, so the pill never overflows.
          child: !active || MediaQuery.sizeOf(context).width < 360
              ? icon
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  // Each tab screen builds its own nav, so "switching tabs"
                  // is a fresh mount: grow the label in from the icon so the
                  // chip reads as expanding into place.
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 380),
                    curve: Curves.easeOutBack,
                    builder: (context, t, label) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        ClipRect(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            widthFactor: t.clamp(0.0, 1.0),
                            child: Opacity(
                              opacity: t.clamp(0.0, 1.0),
                              child: label,
                            ),
                          ),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

/// "Menempel" bottom nav (default): a plain full-width bar fixed to the
/// bottom, every tab always showing icon + label (not only the active one).
/// Respects the safe area; stays well under `kFtFabClearance` so content is
/// never hidden.
class FtFixedBottomNav extends ConsumerWidget {
  const FtFixedBottomNav({
    super.key,
    required this.current,
    this.showAction = true,
  });

  final FtTab current;
  final bool showAction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = showAction && canRecordNav(ref);
    final effective = current == FtTab.goals ? FtTab.assets : current;

    Widget side(List<_FtNavItem> items) => Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final item in items)
                _FtFixedNavButton(item: item, active: item.tab == effective),
            ],
          ),
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: FtColors.navBar,
        border: Border(top: BorderSide(color: FtColors.line, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              side(ftNavItems.sublist(0, 2)),
              if (action) const _NavRecordButton(),
              side(ftNavItems.sublist(2)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FtFixedNavButton extends StatelessWidget {
  const _FtFixedNavButton({required this.item, required this.active});

  final _FtNavItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? FtColors.navActiveInk : FtColors.navIcon;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: FtTapScale(
        scale: 0.94,
        haptic: false,
        onTap: active
            ? null
            : () {
                FtHaptics.select();
                context.go(item.path);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(active ? item.iconActive : item.icon, size: 21, color: color),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FtNavItem {
  const _FtNavItem(this.tab, this.iconActive, this.icon, this.label, this.path);

  final FtTab tab;
  final IconData iconActive;
  final IconData icon;
  final String label;
  final String path;
}
