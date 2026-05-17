import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import 'ft_action_sheet.dart';
import 'ft_haptics.dart';
import 'ft_motion.dart';

export 'ft_motion.dart';

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
  FtProgressBar({
    super.key,
    required this.value,
    required this.max,
    required this.color,
    this.height = 4,
    this.trackColor,
    this.overflowColor,
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
    final over = overflowColor != null && raw > 1.0;
    if (!over) {
      final pct = raw.clamp(0.0, 1.0);
      return ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: height,
          backgroundColor: trackColor ?? FtColors.line,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
    // Two-segment fill: first part full of base color (representing the
    // budgeted spend), then a small wedge of overflowColor for the excess.
    // Total filled = 1.0 because spend is over-max; sized by the over-amount.
    final overFraction = ((raw - 1.0) / raw).clamp(0.0, 1.0);
    final baseFraction = 1.0 - overFraction;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              flex: (baseFraction * 1000).round().clamp(1, 1000),
              child: Container(color: color),
            ),
            Expanded(
              flex: (overFraction * 1000).round().clamp(1, 1000),
              child: Container(color: overflowColor),
            ),
          ],
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
  FtStatItem({
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
class FtAppChrome extends StatelessWidget {
  const FtAppChrome({
    super.key,
    required this.current,
    required this.child,
    this.showNav = true,
    this.showActionFab = true,
  });

  final FtTab current;
  final Widget child;
  final bool showNav;

  /// Hide the floating "+" on screens that already have a contextual entry
  /// (e.g. the dedicated record-expense/record-income screens).
  final bool showActionFab;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
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

class _CatatAktivitasFab extends StatelessWidget {
  const _CatatAktivitasFab();

  @override
  Widget build(BuildContext context) {
    return FtTapScale(
      scale: 0.88,
      onTap: () => ActionChooserSheet.show(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: FtColors.ink,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: FtColors.ink.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(Icons.add_rounded, size: 26, color: FtColors.bg),
      ),
    );
  }
}

enum FtTab { home, spend, assets, goals, cards }

/// Floating glass-pill bottom nav with 5 evenly-spaced tabs. Mirrors the
/// design's `TabBar` in `claude-design/app.jsx` — no central action button.
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
      _FtNavItem(FtTab.home, Icons.home_rounded, Icons.home_outlined,
          'Beranda', '/home'),
      _FtNavItem(FtTab.spend, Icons.donut_large_rounded,
          Icons.donut_large_outlined, 'Pengeluaran', '/spend'),
      _FtNavItem(FtTab.assets, Icons.pie_chart_rounded,
          Icons.pie_chart_outline_rounded, 'Aset', '/accounts'),
      _FtNavItem(FtTab.goals, Icons.flag_rounded, Icons.flag_outlined,
          'Tujuan', '/goals'),
      _FtNavItem(FtTab.cards, Icons.credit_card_rounded,
          Icons.credit_card_outlined, 'Utang', '/cards'),
    ];

    final nav = Row(
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
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: FtColors.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: FtColors.lineStrong, width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: nav,
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
        decoration: BoxDecoration(
          color: active ? FtColors.bg : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? item.iconActive : item.icon,
              size: iconSize,
              color: active ? FtColors.ink : FtColors.ink3,
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: active ? FtColors.ink : FtColors.ink3,
                    fontSize: labelSize,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
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
  const _FtNavItem(
    this.tab,
    this.iconActive,
    this.icon,
    this.label,
    this.path,
  );

  final FtTab tab;
  final IconData iconActive;
  final IconData icon;
  final String label;
  final String path;
}

/// Sub-screen header: cream back button + serif title + optional trailing.
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
            onTap: onBack ??
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
        decoration: BoxDecoration(
          color: FtColors.ink,
          shape: BoxShape.circle,
        ),
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
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              transform: _SlideGradientTransform(
                percent: _ctrl.value,
              ),
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
    return Matrix4.translationValues(
      bounds.width * (percent * 2 - 0.5),
      0,
      0,
    );
  }
}
