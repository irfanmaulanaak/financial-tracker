import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/layout_provider.dart';
import '../features/household/household_providers.dart';
import '../theme.dart';
import 'ft_action_sheet.dart';
import 'ft_bottom_nav.dart';
import 'ft_breakpoints.dart';
import 'ft_glass.dart';
import 'ft_motion.dart';
import 'ft_page_container.dart';
import 'ft_side_nav.dart';

export 'ft_bottom_nav.dart';
export 'ft_breakpoints.dart';
export 'ft_dashed_add.dart';
export 'ft_glass.dart';
export 'ft_motion.dart';
export 'ft_page_container.dart';
export 'ft_progress.dart';
export 'ft_shimmer.dart';
export 'ft_skeleton.dart';
export 'ft_snackbar.dart';

class FtCard extends StatelessWidget {
  const FtCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.backgroundColor,
    this.onTap,
    this.onLongPress,
    this.heroTag,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Optional Hero tag — when set, wraps the card body in a Hero so navigation
  /// to a detail screen with the same tag produces a shared-element transition.
  /// Pair with `ftScaleUpPage` for the cleanest visual handoff.
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    // Liquid: kartu jadi kaca versi lite — wallpaper terlihat menembus
    // (lensa prosedural, tanpa BackdropFilter per kartu yang mahal di list).
    // Kartu dengan backgroundColor eksplisit (aksen) tetap solid.
    final liquid =
        FtColors.liquid &&
        backgroundColor == null &&
        !MediaQuery.highContrastOf(context);
    final Widget card = liquid
        ? FtGlass(
            lite: true,
            borderRadius: BorderRadius.circular(18),
            padding: padding,
            child: child,
          )
        : AnimatedContainer(
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

    final maybeHero = heroTag == null
        ? card
        : Hero(
            tag: heroTag!,
            // Flat surface during flight — Material default forces an
            // opaque container which clashes with our cream theme.
            flightShuttleBuilder: (_, animation, _, _, _) {
              return Material(color: Colors.transparent, child: card);
            },
            child: Material(color: Colors.transparent, child: card),
          );

    final wrapped = onTap == null && onLongPress == null
        ? maybeHero
        : FtTapScale(onTap: onTap, onLongPress: onLongPress, child: maybeHero);

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
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: FtColors.ink,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: FtColors.clay,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom inset for vertical scrollables hosted by [FtAppChrome].
///
/// Clears either bottom nav style — the floating pill (64 + 22 gap) or the
/// fixed bar ([FtFixedBottomNav], 64 + safe area) — plus device safe area.
const double kFtFabClearance = 128;

/// App chrome: keeps the floating pill nav above the screen body. The
/// "Catat Aktivitas" button lives inside the pill on phones. On `medium`+
/// breakpoints the pill becomes a side rail (FtSideNav) with a separate FAB,
/// and the body is width-constrained via `FtPageContainer`.
class FtAppChrome extends ConsumerWidget {
  const FtAppChrome({
    super.key,
    required this.current,
    required this.child,
    this.showNav = true,
    this.showActionFab = true,
    this.constrainBody = true,
  });

  final FtTab current;
  final Widget child;
  final bool showNav;

  /// Hide the "+" on screens that already have a contextual entry
  /// (e.g. the dedicated record-expense/record-income screens).
  final bool showActionFab;

  /// Whether to wrap the body in `FtPageContainer` so content centers and
  /// pins to a comfortable reading width on wide screens. Defaults to true.
  /// Disable for screens that manage their own width constraints (e.g.
  /// full-bleed onboarding screens).
  final bool constrainBody;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = context.isAtLeastMedium;
    final body = constrainBody ? FtPageContainer(child: child) : child;

    if (wide) {
      return Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                if (showNav) FtSideNav(current: current),
                Expanded(child: body),
              ],
            ),
          ),
          if (showNav && showActionFab)
            Positioned(
              right: 24,
              bottom: MediaQuery.paddingOf(context).bottom + 24,
              child: const _CatatAktivitasFab(),
            ),
        ],
      );
    }

    // "Menu bawah" setting: floating pill (default) or a fixed full-width
    // bar. Both stay within `kFtFabClearance` so content is never hidden.
    final navStyle = ref.watch(bottomNavStyleProvider);

    return Stack(
      children: [
        Positioned.fill(child: body),
        if (showNav)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: navStyle == FtNavStyle.fixed
                ? FtFixedBottomNav(
                    current: current, showAction: showActionFab)
                : SafeArea(
                    top: false,
                    minimum: const EdgeInsets.only(bottom: 22),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FtBottomNav(
                          current: current, showAction: showActionFab),
                    ),
                  ),
          ),
      ],
    );
  }
}

/// Whether the current member may record anything (hides "+" for view-only).
bool _canRecord(WidgetRef ref) =>
    ref.watch(canRecordTxnProvider) || ref.watch(canWriteAllProvider);

class _CatatAktivitasFab extends ConsumerWidget {
  const _CatatAktivitasFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_canRecord(ref)) return const SizedBox.shrink();
    return FtTapScale(
      scale: 0.88,
      onTap: () => ActionChooserSheet.show(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: FtColors.fab,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add_rounded, size: 26, color: FtColors.onFab),
      ),
    );
  }
}

enum FtTab { home, spend, assets, goals, cards }

/// Sub-screen header: cream back button + sans title + optional trailing.
/// Honors top safe area (avoids status bar collision on phones without notch).
class FtSubHeader extends StatelessWidget {
  const FtSubHeader({
    super.key,
    required this.title,
    this.trailing,
    this.onBack,
    this.isTab = false,
  });

  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;

  /// Tab root screens (bottom-nav destinations): big bold title, no back
  /// button — the nav already says where you are.
  final bool isTab;

  @override
  Widget build(BuildContext context) {
    // Add system top inset so the header is never under the status bar — works
    // whether or not the parent screen wrapped us in a SafeArea.
    final topPad = MediaQuery.paddingOf(context).top;
    if (isTab) {
      return Padding(
        padding: EdgeInsets.fromLTRB(22, topPad + 20, 16, 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: FtColors.ink,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPad + 10, 16, 10),
      child: Row(
        children: [
          FtTapScale(
            scale: 0.9,
            onTap:
                onBack ??
                () {
                  if (Navigator.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: FtColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: FtColors.line, width: 0.5),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: FtColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 19,
                letterSpacing: -0.3,
                // Pin to the live brightness — `textTheme.titleLarge.color`
                // is baked at theme-build time; this guards against any
                // mismatch between the cached color and the active scheme.
                color: FtColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

