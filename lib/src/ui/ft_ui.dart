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
    // Content stays solid and quiet. Glass is reserved for navigation and
    // transient controls, so financial data remains easy to scan.
    final Widget card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? FtColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FtColors.line),
      ),
      child: child,
    );

    final maybeHero = heroTag == null
        ? card
        : Hero(
            tag: heroTag!,
            // Flat surface during flight — Material default forces an
            // opaque container which clashes with our transparent chrome.
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
    this.prominent = false,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
      child: Row(
        children: [
          Expanded(
            child: prominent
                ? Text(
                    title,
                    style: TextStyle(
                      color: FtColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                : Eyebrow(title),
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
                style: const TextStyle(
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
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

/// App chrome: keeps the floating bottom nav above the screen body, plus a
/// separate "Catat Aktivitas" FAB hovering above the right side of the nav.
/// On `medium`+ breakpoints, switches the bottom nav for a side rail (FtSideNav)
/// and width-constrains the body via `FtPageContainer` so wide-screen layouts
/// stay readable instead of stretching edge-to-edge.
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

  /// Hide the floating "+" on screens that already have a contextual entry
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
              minimum: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                child: FtBottomNav(current: current),
              ),
            ),
          ),
        if (showNav && showActionFab)
          Positioned(
            right: 16,
            // Lift the FAB so it sits clearly above the nav pill while still
            // overlapping its top edge — matches the floating-button feel.
            bottom: MediaQuery.paddingOf(context).bottom + 78,
            child: const _CatatAktivitasFab(),
          ),
      ],
    );
  }
}

class _CatatAktivitasFab extends ConsumerWidget {
  const _CatatAktivitasFab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hide the FAB for view-only members — nothing to record from here.
    if (!ref.watch(canRecordTxnProvider) && !ref.watch(canWriteAllProvider)) {
      return const SizedBox.shrink();
    }
    return FtTapScale(
      scale: 0.88,
      onTap: () => ActionChooserSheet.show(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: FtColors.clay,
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
        child: const Icon(Icons.add_rounded, size: 26, color: Colors.white),
      ),
    );
  }
}

enum FtTab { home, spend, assets, goals, cards }

/// Floating glass bottom nav with five evenly-spaced destinations.
///
/// A single translucent selection lens moves between tabs so navigation reads
/// as one continuous control instead of five unrelated buttons.
class FtBottomNav extends StatelessWidget {
  const FtBottomNav({super.key, required this.current});

  final FtTab current;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 360;
    final labelSize = compact ? 9.0 : 9.5;
    final iconSize = compact ? 19.0 : 20.0;

    final items = const [
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
        FtTab.assets,
        Icons.pie_chart_rounded,
        Icons.pie_chart_outline_rounded,
        'Aset',
        '/accounts',
      ),
      _FtNavItem(
        FtTab.goals,
        Icons.flag_rounded,
        Icons.flag_outlined,
        'Tujuan',
        '/goals',
      ),
      _FtNavItem(
        FtTab.cards,
        Icons.credit_card_rounded,
        Icons.credit_card_outlined,
        'Utang',
        '/cards',
      ),
    ];

    final activeIndex = items.indexWhere((it) => it.tab == current);
    // Maps the active index to a -1..1 range over `tabCount-1` cells, so the
    // pill lands exactly under the active cell at every step.
    final align = items.length <= 1
        ? -1.0
        : (activeIndex / (items.length - 1)) * 2 - 1;

    final liquid = FtColors.liquid;
    return FtGlass(
      borderRadius: BorderRadius.circular(28),
      fallbackAlpha: 0.94,
      fallbackBorderColor: FtColors.lineStrong,
      boxShadow: const [
        BoxShadow(
          color: Color(0x1A000000),
          blurRadius: 28,
          offset: Offset(0, 10),
        ),
      ],
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        height: 52,
        child: Stack(
          children: [
            // Floating pill — fractionally 1/N wide so it lands under one
            // cell regardless of available width. Positioned.fill gives
            // it the full Stack to align within.
            Positioned.fill(
              child: AnimatedAlign(
                duration: Duration(milliseconds: liquid ? 320 : 240),
                curve: Curves.easeOutCubic,
                alignment: Alignment(align, 0),
                child: FractionallySizedBox(
                  widthFactor: 1.0 / items.length,
                  heightFactor: 0.82,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: liquid
                          ? Colors.white.withValues(
                              alpha:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? 0.06
                                  : 0.12,
                            )
                          : FtColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (final item in items)
                  Expanded(
                    child: _FtNavButton(
                      item: item,
                      active: current == item.tab,
                      labelSize: labelSize,
                      iconSize: iconSize,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FtNavButton extends StatelessWidget {
  const _FtNavButton({
    required this.item,
    required this.active,
    required this.labelSize,
    required this.iconSize,
  });

  final _FtNavItem item;
  final bool active;
  final double labelSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
        // The active pill is now drawn by the parent Stack — leave the button
        // background transparent so the slide animation isn't double-drawn.
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: Icon(
                active ? item.iconActive : item.icon,
                key: ValueKey(active),
                size: iconSize,
                color: active ? FtColors.clay : FtColors.ink3,
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    color: active ? FtColors.clay : FtColors.ink3,
                    fontSize: labelSize,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _FtNavItem {
  const _FtNavItem(this.tab, this.iconActive, this.icon, this.label, this.path);

  final FtTab tab;
  final IconData iconActive;
  final IconData icon;
  final String label;
  final String path;
}

/// Sub-screen header: back button + title + optional trailing.
/// Honors top safe area (avoids status bar collision on phones without notch).
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
    // Add system top inset so the header is never under the status bar — works
    // whether or not the parent screen wrapped us in a SafeArea.
    final topPad = MediaQuery.paddingOf(context).top;
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
                fontWeight: FontWeight.w500,
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
/// lists (cards, goals, accounts, investments). Full-width, transparent fill,
/// dashed outline, small plus icon + label.
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
    final disabled = MediaQuery.disableAnimationsOf(context);
    if (disabled && _ctrl.isAnimating) {
      _ctrl.stop();
    } else if (!disabled && !_ctrl.isAnimating) {
      _ctrl.repeat();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return widget.child;
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
