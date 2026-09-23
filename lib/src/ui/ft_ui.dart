import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/household/household_providers.dart';
import '../theme.dart';
import 'ft_action_sheet.dart';
import 'ft_breakpoints.dart';
import 'ft_glass.dart';
import 'ft_haptics.dart';
import 'ft_motion.dart';
import 'ft_page_container.dart';
import 'ft_side_nav.dart';

export 'ft_breakpoints.dart';
export 'ft_glass.dart';
export 'ft_motion.dart';
export 'ft_page_container.dart';
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

Color ftProgressColor(num value, num max, {bool dangerWhenOver = false}) {
  if (dangerWhenOver && max > 0 && value > max) {
    return FtColors.danger;
  }
  final ratio = max <= 0 ? 0.0 : value / max;
  return ratio >= 0.8 ? FtColors.ink : FtColors.ink.withValues(alpha: 0.7);
}

class FtProgressBar extends StatelessWidget {
  const FtProgressBar({
    super.key,
    required this.value,
    required this.max,
    required this.color,
    this.height = 4,
    this.trackColor,
    this.overflowColor,
    this.animationDuration = const Duration(milliseconds: 360),
  });

  final num value;
  final num max;
  final Color color;
  final double height;
  final Color? trackColor;

  /// When `value > max`, the visible track is split: filled portion = base color,
  /// remaining = overflowColor (typically `FtColors.danger`). Matches design's
  /// `Bar overflowColor={theme.danger}` from `screens-home.jsx`.
  final Color? overflowColor;

  /// How long to animate when [value] or [max] changes. Set to `Duration.zero`
  /// to disable. Honors `MediaQuery.disableAnimations` automatically.
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    if (max <= 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: 0,
          minHeight: height,
          backgroundColor: trackColor ?? FtColors.line,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
    final raw = (value / max).toDouble();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : animationDuration;

    final over = overflowColor != null && raw > 1.0;
    if (!over) {
      final target = raw.clamp(0.0, 1.0);
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: target, end: target),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (_, v, _) {
            return LinearProgressIndicator(
              value: v,
              minHeight: height,
              backgroundColor: trackColor ?? FtColors.line,
              valueColor: AlwaysStoppedAnimation(color),
            );
          },
        ),
      );
    }
    final overFraction = ((raw - 1.0) / raw).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: overFraction, end: overFraction),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (_, of, _) {
            final base = 1.0 - of;
            return Row(
              children: [
                Expanded(
                  flex: (base * 1000).round().clamp(1, 1000),
                  child: Container(color: color),
                ),
                Expanded(
                  flex: (of * 1000).round().clamp(1, 1000),
                  child: Container(color: overflowColor),
                ),
              ],
            );
          },
        ),
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
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
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
            color: color ?? FtColors.ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Bottom inset for vertical scrollables hosted by [FtAppChrome].
///
/// Clears the floating pill nav (64 + 22 gap) and device safe area.
const double kFtFabClearance = 128;

/// App chrome: keeps the floating pill nav above the screen body. The
/// "Catat Aktivitas" button lives inside the pill on phones. On `medium`+
/// breakpoints the pill becomes a side rail (FtSideNav) with a separate FAB,
/// and the body is width-constrained via `FtPageContainer`.
class FtAppChrome extends StatelessWidget {
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
  Widget build(BuildContext context) {
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

    return Stack(
      children: [
        Positioned.fill(child: body),
        if (showNav)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: 22),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FtBottomNav(current: current, showAction: showActionFab),
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

/// Floating pill bottom nav ("Gelap tenang" style): 4 tabs with the record
/// button in the middle. The active tab grows into a chip with icon +
/// label; the others are icon-only.
class FtBottomNav extends ConsumerWidget {
  const FtBottomNav({super.key, required this.current, this.showAction = true});

  final FtTab current;

  /// Show the "+" record button inside the pill.
  final bool showAction;

  static const _items = [
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
      'Belanja',
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final action = showAction && _canRecord(ref);
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

class _FtNavItem {
  const _FtNavItem(this.tab, this.iconActive, this.icon, this.label, this.path);

  final FtTab tab;
  final IconData iconActive;
  final IconData icon;
  final String label;
  final String path;
}

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

/// Dashed-bordered "Tambah X" button rendered at the bottom of management
/// lists (cards, goals, accounts, investments). Matches the pattern from
/// `claude-design/screens-assets.jsx` — full-width, transparent fill, dashed
/// outline, small plus icon + label.
class FtDashedAdd extends StatelessWidget {
  const FtDashedAdd({
    super.key,
    required this.label,
    required this.onTap,
    this.margin,
  });

  final String label;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final wrapped = FtTapScale(
      scale: 0.98,
      onTap: onTap,
      child: DottedBorderBox(
        color: FtColors.lineStrong,
        radius: 12,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 14, color: FtColors.ink2),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: FtColors.ink2,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (margin == null) return wrapped;
    return Padding(padding: margin!, child: wrapped);
  }
}

/// Custom-painted dashed border box, used by [FtDashedAdd] since Flutter
/// has no built-in dashed border support for [Container].
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({
    super.key,
    required this.child,
    required this.color,
    this.radius = 12,
    this.strokeWidth = 0.8,
    this.dashLength = 5,
    this.gapLength = 4,
  });

  final Widget child;
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: color,
        radius: radius,
        strokeWidth: strokeWidth,
        dashLength: dashLength,
        gapLength: gapLength,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });
  final Color color;
  final double radius;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);
    final metrics = path.computeMetrics().toList();
    for (final m in metrics) {
      var distance = 0.0;
      while (distance < m.length) {
        final next = (distance + dashLength).clamp(0.0, m.length);
        canvas.drawPath(m.extractPath(distance, next), paint);
        distance = next + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength;
}

/// Small "+" pill used by sub-screens (cards, goals, accounts, etc.) — dark
/// circular button with light icon, matches the design's add affordance.
class FtAddButton extends StatelessWidget {
  const FtAddButton({super.key, required this.onTap, this.tooltip});

  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final child = FtTapScale(
      scale: 0.9,
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: FtColors.ink, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Icon(Icons.add_rounded, size: 20, color: FtColors.bg),
      ),
    );
    return tooltip == null ? child : Tooltip(message: tooltip!, child: child);
  }
}

/// Skeleton shimmer loader. Shows a shifting gradient over placeholder blocks.
class FtShimmer extends StatefulWidget {
  const FtShimmer({super.key, required this.child});
  final Widget child;

  @override
  State<FtShimmer> createState() => _FtShimmerState();
}

class _FtShimmerState extends State<FtShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool? _disableAnimations;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    if (disableAnimations != _disableAnimations) {
      _disableAnimations = disableAnimations;
      if (_disableAnimations == true) {
        _ctrl.stop();
      } else {
        _ctrl.repeat();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_disableAnimations == true) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                FtColors.surfaceAlt,
                FtColors.lineStrong,
                FtColors.surfaceAlt,
              ],
              stops: const [0.0, 0.5, 1.0],
              transform: _SlideGradientTransform(percent: _ctrl.value),
            ).createShader(bounds);
          },
          blendMode: BlendMode.srcIn,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlideGradientTransform extends GradientTransform {
  const _SlideGradientTransform({required this.percent});
  final double percent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (percent * 2 - 0.5), 0, 0);
  }
}
