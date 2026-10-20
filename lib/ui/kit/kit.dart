/// The Volt component kit: one widget per class in the Gymco Volt prototype's
/// stylesheet, with its sizes, radii, colours and weights copied across.
/// Screens compose these; they should not invent their own surfaces.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../theme/volt.dart';
import 'icon_paths.dart';
import 'motion.dart';

export 'motion.dart';

const _tab = [FontFeature.tabularFigures()];

// ---------------------------------------------------------------- text

/// `.eyebrow`: 11/600, uppercase, tracked, lime ink.
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color, this.padding = EdgeInsets.zero});
  final String text;
  final Color? color;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(
      text.toUpperCase(),
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.88, color: color ?? Volt.brandInk),
    ),
  );
}

/// `.muted`: 12, t3, line height 1.5.
class Muted extends StatelessWidget {
  const Muted(this.text, {super.key, this.color, this.align, this.size = 12});
  final String text;
  final Color? color;
  final TextAlign? align;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: align,
    style: TextStyle(fontSize: size, height: 1.5, color: color ?? Volt.t3),
  );
}

/// Tabular numbers, as `.num` sets them.
TextStyle numStyle(double size, {FontWeight weight = FontWeight.w600, Color? color, double? height}) => TextStyle(
  fontSize: size,
  fontWeight: weight,
  color: color ?? Volt.t1,
  height: height,
  fontFeatures: _tab,
  letterSpacing: 0.07,
);

/// A title with one word in the serif italic accent: `Make it <em>count</em>`.
/// [title] marks the accent with `<em>…</em>`.
class EmTitle extends StatelessWidget {
  const EmTitle(
    this.title, {
    super.key,
    this.size = 27,
    this.weight = FontWeight.w800,
    this.emScale = 1.14,
    this.letterSpacing = -0.025,
    this.height = 1.08,
    this.align,
  });
  final String title;
  final TextAlign? align;
  final double size;
  final FontWeight weight;
  final double emScale;
  final double letterSpacing;
  final double height;

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final base = TextStyle(
      fontSize: size,
      fontWeight: weight,
      letterSpacing: size * letterSpacing,
      height: height,
      color: Volt.t1,
    );
    final em = arabic
        ? base.copyWith(color: Volt.accentInk)
        : TextStyle(
            fontFamily: 'InstrumentSerif',
            fontFamilyFallback: const ['IBMPlexSansArabic'],
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w400,
            fontSize: size * emScale,
            letterSpacing: -0.005 * size,
            color: Volt.accentInk,
            height: height,
          );
    final spans = <TextSpan>[];
    final re = RegExp(r'<em>(.*?)</em>');
    var at = 0;
    for (final m in re.allMatches(title)) {
      if (m.start > at) spans.add(TextSpan(text: title.substring(at, m.start)));
      spans.add(TextSpan(text: m.group(1), style: em));
      at = m.end;
    }
    if (at < title.length) spans.add(TextSpan(text: title.substring(at)));
    return Text.rich(
      TextSpan(style: base, children: spans),
      textAlign: align,
    );
  }
}

// ---------------------------------------------------------------- icons

/// An icon from the prototype's set, drawn in [color] at [size].
class VIcon extends StatelessWidget {
  const VIcon(this.name, {super.key, this.size = 20, this.color, this.strokeWidth = 1.5});
  final String name;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color ?? Volt.t1;
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="$strokeWidth">${voltIconPaths[name] ?? ''}</svg>';
    final pic = SizedBox.square(
      dimension: size,
      child: SvgPicture.string(
        svg,
        width: size,
        height: size,
        theme: SvgTheme(currentColor: c),
      ),
    );
    // Arrows point the way the reading goes.
    final rtl = Directionality.maybeOf(context) == TextDirection.rtl;
    return rtl && (name == 'fwd' || name == 'back') ? Transform.flip(flipX: true, child: pic) : pic;
  }
}

// ---------------------------------------------------------------- the screen

/// `.screen`: near-black with a lime glow rising behind the top.
class VScreen extends StatelessWidget {
  const VScreen({super.key, required this.child, this.overlays = const []});
  final Widget child;

  /// Floating bars (log bar, rest bar, tab bar) stacked over the content.
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Volt.isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: Material(
        color: Volt.bg,
        child: CustomPaint(
          painter: const _GlowPainter(),
          child: SafeArea(
            bottom: false,
            // Expand: an overlay that draws nothing must not shrink the screen.
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: child),
                ...overlays,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter();

  void _ellipse(Canvas c, Size s, Offset at, double rx, double ry, Color color) {
    c.save();
    c.translate(at.dx, at.dy);
    c.scale(rx, ry);
    final p = Paint()..shader = ui.Gradient.radial(Offset.zero, 1, [color, color.withValues(alpha: 0)], [0, 0.7]);
    c.drawCircle(Offset.zero, 1, p);
    c.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    // radial-gradient(90% 38% at 85% -6%, rgba(198,244,50,.20), transparent 70%)
    // On the light page the lime needs more strength to show at all.
    _ellipse(
      canvas,
      size,
      Offset(size.width * 0.85, -size.height * 0.06),
      size.width * 0.9,
      size.height * 0.38,
      Volt.isLight ? const Color(0x2EC6F432) : const Color(0x33C6F432),
    );
    // radial-gradient(70% 30% at 0% 0%, rgba(94,228,160,.10), transparent 70%)
    _ellipse(
      canvas,
      size,
      Offset.zero,
      size.width * 0.7,
      size.height * 0.3,
      Volt.isLight ? const Color(0x145EE4A0) : const Color(0x1A5EE4A0),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// `.pad`: 16 px sides, 12 px between children. [bottom] clears the tab bar.
/// What is on screen when it opens eases in a card at a time; anything
/// scrolled to later is simply there.
class Pad extends StatefulWidget {
  const Pad({super.key, required this.children, this.top = 0, this.bottom = 116, this.gap = 12, this.controller});
  final List<Widget> children;
  final double top;
  final double bottom;
  final double gap;
  final ScrollController? controller;

  @override
  State<Pad> createState() => _PadState();
}

class _PadState extends State<Pad> {
  final _opened = DateTime.now();

  @override
  Widget build(BuildContext context) => ListView.separated(
    controller: widget.controller,
    padding: EdgeInsets.fromLTRB(16, widget.top, 16, widget.bottom + MediaQuery.paddingOf(context).bottom),
    itemCount: widget.children.length,
    separatorBuilder: (_, _) => SizedBox(height: widget.gap),
    itemBuilder: (_, i) {
      final play = i <= 8 && DateTime.now().difference(_opened) < const Duration(milliseconds: 500);
      return Entrance(
        delay: Duration(milliseconds: 45 * i),
        play: play,
        child: widget.children[i],
      );
    },
  );
}

/// `.appbar`: 22/16/12 padding; title 27/800 with the serif accent.
class VAppBar extends StatelessWidget {
  const VAppBar({super.key, required this.title, this.sub, this.right, this.logo = false, this.titleSize = 27});
  final String title;
  final String? sub;
  final Widget? right;
  final bool logo;
  final double titleSize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
    child: Row(
      children: [
        if (logo) ...[const VLogo(size: 45), const SizedBox(width: 12)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EmTitle(title, size: titleSize),
              if (sub != null) ...[
                const SizedBox(height: 3),
                Text(sub!, style: TextStyle(fontSize: 12.5, color: Volt.t3)),
              ],
            ],
          ),
        ),
        if (right != null) ...[const SizedBox(width: 12), right!],
      ],
    ),
  );
}

/// The app bars most inner screens draw: a back (or close) button, a title
/// and a muted line under it, an optional action.
class BackBar extends StatelessWidget {
  const BackBar({
    super.key,
    required this.title,
    this.sub,
    this.onBack,
    this.icon = 'back',
    this.right,
    this.lead,
    this.titleSize = 17,
    this.backLabel,
  });
  final String title;
  final String? sub;
  final VoidCallback? onBack;
  final String icon;
  final Widget? right;
  final Widget? lead;
  final double titleSize;
  final String? backLabel;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
    child: Row(
      children: [
        IconBtn(
          icon,
          small: true,
          iconSize: 18,
          label: backLabel ?? MaterialLocalizations.of(context).backButtonTooltip,
          onTap: onBack ?? () => Navigator.of(context).maybePop(),
        ),
        const SizedBox(width: 10),
        if (lead != null) ...[lead!, const SizedBox(width: 10)],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600, color: Volt.t1),
              ),
              if (sub != null) ...[const SizedBox(height: 1), Muted(sub!)],
            ],
          ),
        ),
        if (right != null) ...[const SizedBox(width: 10), right!],
      ],
    ),
  );
}

/// The Gymco mark, filled with the primary gradient.
class VLogo extends StatelessWidget {
  const VLogo({super.key, this.size = 45});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Gymco',
    image: true,
    // Lime glow on dark; plain ink on light, where the glow washes out.
    child: Volt.isLight
        ? Image.asset('assets/brand/logo-mask.png', width: size, height: size, color: Volt.t1)
        : ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (r) => Volt.glow.createShader(r),
            child: Image.asset('assets/brand/logo-mask.png', width: size, height: size),
          ),
  );
}

// ---------------------------------------------------------------- surfaces

/// `.card`: card ground, radius 24, 16 padding. [tight] is 14/16.
class VCard extends StatelessWidget {
  const VCard({
    super.key,
    required this.child,
    this.tight = false,
    this.padding,
    this.onTap,
    this.color,
    this.border,
    this.radius = 18,
  });
  final Widget child;
  final bool tight;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final BoxBorder? border;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final p = padding ?? (tight ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14) : const EdgeInsets.all(16));
    final body = Container(
      padding: p,
      decoration: BoxDecoration(
        color: color ?? Volt.card,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Volt.edge,
      ),
      child: child,
    );
    if (onTap == null) return body;
    return Pressable(onTap: onTap!, scale: 0.99, radius: radius, child: body);
  }
}

/// `.list` holding `.item`s: one card, hairlines between rows.
class VList extends StatelessWidget {
  const VList({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: Volt.card, borderRadius: BorderRadius.circular(18), border: Volt.edge),
    child: Material(
      type: MaterialType.transparency,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: Volt.line),
            children[i],
          ],
        ],
      ),
    ),
  );
}

/// `.item`: min 56 high, 11/16 padding, 12 gap.
class VItem extends StatelessWidget {
  const VItem({super.key, required this.children, this.onTap, this.color, this.semantics});
  final List<Widget> children;
  final VoidCallback? onTap;
  final Color? color;
  final String? semantics;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      color: color,
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      child: Row(children: _gap(children, 12)),
    );
    if (onTap == null) return row;
    return Semantics(
      button: true,
      label: semantics,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, child: row),
      ),
    );
  }
}

/// The two-line middle of an item: `.nm` over `.sb`.
class ItemText extends StatelessWidget {
  const ItemText(this.name, {super.key, this.sub, this.weight = FontWeight.w500, this.trailingName, this.subColor});
  final String name;
  final String? sub;
  final FontWeight weight;
  final Widget? trailingName;
  final Color? subColor;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 15, fontWeight: weight, color: Volt.t1),
              ),
            ),
            if (trailingName != null) ...[const SizedBox(width: 6), trailingName!],
          ],
        ),
        if (sub != null) ...[
          const SizedBox(height: 2),
          Text(
            sub!,
            style: TextStyle(fontSize: 12, color: subColor ?? Volt.t3, fontFeatures: _tab),
          ),
        ],
      ],
    ),
  );
}

/// CSS `gap` between every pair of flex children, Spacers excepted.
List<Widget> _gap(List<Widget> ws, double g) => [
  for (var i = 0; i < ws.length; i++) ...[
    if (i > 0 && ws[i] is! Spacer && ws[i - 1] is! Spacer) SizedBox(width: g),
    ws[i],
  ],
];

/// A row with the CSS `gap`, handy for the prototype's `.row`.
class GapRow extends StatelessWidget {
  const GapRow({super.key, required this.children, this.gap = 12, this.cross = CrossAxisAlignment.center});
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment cross;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: cross,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(width: gap), children[i]],
    ],
  );
}

class GapCol extends StatelessWidget {
  const GapCol({super.key, required this.children, this.gap = 12, this.cross = CrossAxisAlignment.start});
  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment cross;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: cross,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
    ],
  );
}

// ---------------------------------------------------------------- controls

/// Scales down while pressed, as every tappable surface does in the prototype.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.95,
    this.radius = 999,
    this.label,
  });
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final double radius;
  final String? label;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? widget.scale : 1,
          duration: const Duration(milliseconds: 160),
          curve: const Cubic(0.22, 1, 0.36, 1),
          child: widget.child,
        ),
      ),
    );
  }
}

enum BtnKind { primary, ghost, start }

/// `.btn`: a glowing lime pill. [small] is `.btn.sm`; [kind] picks ghost or start.
class VBtn extends StatelessWidget {
  const VBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.kind = BtnKind.primary,
    this.small = false,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.minHeight,
    this.padding,
    this.fontSize,
    this.color,
    this.child,
  });
  final String label;
  final VoidCallback? onTap;
  final BtnKind kind;
  final bool small;
  final String? icon;
  final String? trailingIcon;
  final bool expand;
  final double? minHeight;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  /// Overrides the label colour (the prototype tints some ghost buttons).
  final Color? color;

  /// Replaces the label row entirely (hero and two-line buttons).
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final primary = kind == BtnKind.primary;
    final fg =
        color ??
        switch (kind) {
          BtnKind.primary => Volt.ink,
          BtnKind.ghost => Volt.t1,
          BtnKind.start => Volt.brandInk,
        };
    final h = minHeight ?? (kind == BtnKind.start ? 36 : (small ? 44 : 52));
    final style = TextStyle(
      fontSize: fontSize ?? (small ? 14 : 15),
      fontWeight: primary ? FontWeight.w800 : FontWeight.w600,
      letterSpacing: 0.075,
      color: fg,
    );
    final content =
        child ??
        Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[VIcon(icon!, size: 18, color: fg), const SizedBox(width: 8)],
            Flexible(
              child: Text(label, textAlign: TextAlign.center, style: style, maxLines: 2),
            ),
            if (trailingIcon != null) ...[const SizedBox(width: 8), VIcon(trailingIcon!, size: 18, color: fg)],
          ],
        );
    final box = AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.45,
      child: Container(
        constraints: BoxConstraints(minHeight: h),
        padding: padding ?? EdgeInsets.symmetric(horizontal: kind == BtnKind.start ? 16 : (small ? 18 : 20)),
        alignment: expand ? Alignment.center : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: primary ? Volt.glow : null,
          color: primary ? null : (kind == BtnKind.ghost ? Volt.card2 : Volt.brandWash),
          boxShadow: primary && enabled
              ? const [BoxShadow(color: Color(0xBFB6F02A), blurRadius: 26, offset: Offset(0, 12), spreadRadius: -12)]
              : null,
        ),
        child: DefaultTextStyle.merge(
          style: style,
          child: IconTheme(
            data: IconThemeData(color: fg),
            child: content,
          ),
        ),
      ),
    );
    return Pressable(onTap: onTap, label: child == null ? null : label, child: box);
  }
}

/// `.chip`: 36 high outlined pill; lime ring when [on].
class VChip extends StatelessWidget {
  const VChip({
    super.key,
    required this.label,
    this.onTap,
    this.on = false,
    this.icon,
    this.iconSize = 13,
    this.flat = false,
    this.height = 36,
    this.color,
    this.textColor,
  });
  final String label;
  final VoidCallback? onTap;
  final bool on;
  final String? icon;
  final double iconSize;
  final bool flat;
  final double height;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final fg = textColor ?? (on ? Volt.accentInk : Volt.t2);
    final chip = Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color ?? (on ? Colors.transparent : Volt.card),
        borderRadius: BorderRadius.circular(999),
        // Flat surfaces: an unselected chip has no visible edge.
        border: Border.all(color: on ? Volt.lime : (Volt.isLight ? Volt.line : Colors.transparent), width: 1.5),
        boxShadow: on ? const [BoxShadow(color: Color(0x1AC6F432), spreadRadius: 3)] : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[VIcon(icon!, size: iconSize, color: fg), const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: on ? FontWeight.w600 : FontWeight.w500, color: fg),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      selected: on,
      child: Pressable(onTap: onTap, child: chip),
    );
  }
}

/// `.iconbtn`: a 44 (or 40) round button on card-2.
class IconBtn extends StatelessWidget {
  const IconBtn(
    this.icon, {
    super.key,
    required this.onTap,
    required this.label,
    this.small = false,
    this.iconSize = 20,
    this.background,
    this.color,
    this.size,
  });
  final String icon;
  final VoidCallback? onTap;
  final String label;
  final bool small;
  final double iconSize;
  final Color? background;
  final Color? color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final d = size ?? (small ? 40.0 : 44.0);
    return Tooltip(
      message: label,
      child: Pressable(
        onTap: onTap,
        label: label,
        child: Container(
          width: d,
          height: d,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: background ?? Volt.card2, shape: BoxShape.circle),
          child: VIcon(icon, size: iconSize, color: color ?? Volt.t1),
        ),
      ),
    );
  }
}

/// `.tag`: 28 high, card-2, 12 px.
class VTag extends StatelessWidget {
  const VTag(this.text, {super.key, this.background, this.color, this.bold = false});
  final String text;
  final Color? background;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) => Container(
    height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 11),
    decoration: BoxDecoration(color: background ?? Volt.card2, borderRadius: BorderRadius.circular(999)),
    child: Center(
      widthFactor: 1,
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color ?? Volt.t2, fontWeight: bold ? FontWeight.w600 : FontWeight.w400),
      ),
    ),
  );
}

/// `.bar`: a 6 px pill track with a coloured fill that grows in.
class VBar extends StatelessWidget {
  const VBar({super.key, required this.fraction, required this.color, this.height = 6, this.track});
  final double fraction;
  final Color color;
  final double height;
  final Color? track;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(999),
    child: SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(child: ColoredBox(color: track ?? Volt.line)),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0, 1).toDouble()),
            duration: const Duration(milliseconds: 800),
            curve: const Cubic(0.22, 1, 0.36, 1),
            builder: (_, v, _) => FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              alignment: AlignmentDirectional.centerStart,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999)),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// `.pick`: the 28 px round add/check at the end of a row.
class Pick extends StatelessWidget {
  const Pick({super.key, this.on = false, this.color});
  final bool on;
  final Color? color;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    curve: voltEase,
    width: 28,
    height: 28,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: on ? Volt.brand : Volt.brand.withValues(alpha: 0),
      border: Border.all(color: on ? Volt.lime : (color ?? Volt.line2)),
    ),
    // The plus turns into a tick.
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (c, a) => RotationTransition(
        turns: Tween<double>(begin: -0.25, end: 0).animate(a),
        child: ScaleTransition(scale: a, child: c),
      ),
      child: VIcon(on ? 'check' : 'plus', key: ValueKey(on), size: 15, color: on ? Volt.ink : (color ?? Volt.t1)),
    ),
  );
}

/// `.mealico`: sunrise, sun, moon, apple in a round badge.
class MealIco extends StatelessWidget {
  const MealIco({super.key, required this.meal, this.on = false, this.size = 36});
  final int meal;
  final bool on;
  final double size;

  static const _icons = ['bfast', 'lunch', 'dinner', 'snack'];

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(shape: BoxShape.circle, color: on ? Volt.brandWash : Volt.card2),
    child: VIcon(_icons[meal], size: (size * 0.52).roundToDouble(), color: on ? Volt.brandInk : Volt.t3),
  );
}

/// `.exav`: the equipment badge (BB, DB, CB…).
class ExAv extends StatelessWidget {
  const ExAv(this.badge, {super.key, this.small = false});
  final String badge;
  final bool small;

  @override
  Widget build(BuildContext context) => Container(
    width: small ? 26 : 34,
    height: small ? 26 : 34,
    alignment: Alignment.center,
    decoration: BoxDecoration(color: Volt.card2, borderRadius: BorderRadius.circular(small ? 9 : 12)),
    // No equipment to name: a dumbbell says "exercise" better than a dot.
    child: badge == '•' || badge == '··'
        ? VIcon('dumb', size: small ? 14 : 18, color: Volt.t3)
        : Text(
            badge,
            style: TextStyle(
              fontSize: small ? 9.5 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.22,
              color: Volt.t3,
            ),
          ),
  );
}

/// `.stepper`: − value + in a card-2 pill.
class VStepper extends StatelessWidget {
  const VStepper({
    super.key,
    required this.label,
    required this.onMinus,
    required this.onPlus,
    this.minusLabel,
    this.plusLabel,
  });
  final String label;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;
  final String? minusLabel;
  final String? plusLabel;

  Widget _b(String icon, VoidCallback? f, String? semantic) => Opacity(
    opacity: f == null ? 0.35 : 1,
    child: Pressable(
      onTap: f,
      label: semantic,
      child: SizedBox.square(
        dimension: 28,
        child: Center(child: VIcon(icon, size: 16, color: Volt.t2)),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Container(
    height: 32,
    padding: const EdgeInsets.all(2),
    decoration: BoxDecoration(color: Volt.card2, borderRadius: BorderRadius.circular(999)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _b('minus', onMinus, minusLabel),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 54),
          child: Text(label, textAlign: TextAlign.center, style: numStyle(13)),
        ),
        _b('plus', onPlus, plusLabel),
      ],
    ),
  );
}

/// `.srow`: a sheet row, 54 high, radius 18; lime-bordered when [on].
class SRow extends StatelessWidget {
  const SRow({super.key, required this.label, this.sub, this.onTap, this.on = false, this.tint, this.lead, this.trail});
  final String label;
  final String? sub;
  final VoidCallback? onTap;
  final bool on;
  final Color? tint;
  final Widget? lead;
  final Widget? trail;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    scale: 0.99,
    radius: 18,
    child: Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: on ? Volt.brandWash : Volt.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: on ? Volt.lime : (Volt.isLight ? Volt.line : Colors.transparent)),
      ),
      child: Row(
        children: [
          if (lead != null) ...[lead!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tint ?? Volt.t1),
                ),
                if (sub != null) ...[const SizedBox(height: 2), Muted(sub!)],
              ],
            ),
          ),
          if (trail != null) ...[const SizedBox(width: 12), trail!],
        ],
      ),
    ),
  );
}

/// `.rchip`: the rest/rep grid buttons in sheets.
class RChip extends StatelessWidget {
  const RChip({super.key, required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    label: label,
    child: Container(
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: on ? Volt.brand : Volt.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: on ? Volt.lime : Volt.line),
      ),
      child: Text(
        label,
        style: numStyle(14, weight: on ? FontWeight.w600 : FontWeight.w400, color: on ? Volt.ink : Volt.t2),
      ),
    ),
  );
}

/// A grid of [RChip]s, [columns] across with 8 px gaps.
class RGrid extends StatelessWidget {
  const RGrid({super.key, required this.children, this.columns = 4});
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, c) {
      final w = (c.maxWidth - 8 * (columns - 1)) / columns;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    },
  );
}

// ---------------------------------------------------------------- sheets

/// `.sheet` + `.sheetcard`: dimmed backdrop, #111315 card with a grab handle,
/// a 17/600 title and a round close button.
Future<T?> showVSheet<T>(
  BuildContext context, {
  required String title,
  required List<Widget> Function(BuildContext) body,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Volt.sheet,
    barrierColor: const Color(0x73000000),
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.86),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (ctx) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, 10, 14, 22 + MediaQuery.viewInsetsOf(ctx).bottom),
        child: SingleChildScrollView(
          child: GapCol(
            gap: 10,
            cross: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(color: Volt.line2, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Volt.t1),
                      ),
                    ),
                    IconBtn(
                      'close',
                      small: true,
                      iconSize: 18,
                      label: MaterialLocalizations.of(ctx).closeButtonTooltip,
                      onTap: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              ...body(ctx),
            ],
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------- floating bars

/// `.logbar`: the glass pill that floats above the tab bar.
class LogBar extends StatelessWidget {
  const LogBar({super.key, required this.children, this.aboveTabs = true, this.padding});
  final List<Widget> children;
  final bool aboveTabs;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    // With the keyboard up the tab bar hides, so the bar sits on the keyboard.
    final keyboard = View.of(context).viewInsets.bottom > 0;
    final safe = keyboard ? 0.0 : MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 14,
      right: 14,
      bottom: (aboveTabs && !keyboard ? 88 : 10) + safe,
      child: _Glass(
        radius: 999,
        color: Volt.isLight ? const Color(0xE6FFFFFF) : const Color(0xDB15171A),
        child: Padding(
          padding: padding ?? const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
          child: Row(children: _gap(children, 12)),
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, required this.radius, required this.color, this.blur = 20, this.shadow});
  final Widget child;
  final double radius;
  final Color color;
  final double blur;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow:
          shadow ??
          [
            BoxShadow(
              color: Volt.isLight ? const Color(0x2E343A2C) : const Color(0x73000000),
              blurRadius: 30,
              offset: const Offset(0, 12),
              spreadRadius: -12,
            ),
          ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur / 2, sigmaY: blur / 2),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Volt.tint.withValues(alpha: Volt.isLight ? 0.06 : 0.06)),
          ),
          child: child,
        ),
      ),
    ),
  );
}

/// The Volt tab bar: labelled tabs, a glowing dash over the current one, and
/// the round lime Train button raised in the middle.
class VTabBar extends StatelessWidget {
  const VTabBar({super.key, required this.current, required this.onTap, required this.labels});
  final int current;
  final ValueChanged<int> onTap;
  final List<String> labels;

  static const icons = ['home', 'food', 'dumb', 'chart', 'user'];

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 12 + safe,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _Glass(
            radius: 30,
            color: Volt.isLight ? const Color(0xEBFFFFFF) : const Color(0xEB15171A),
            blur: 22,
            shadow: [
              BoxShadow(
                color: Volt.isLight ? const Color(0x33343A2C) : Colors.black,
                blurRadius: 44,
                offset: const Offset(0, 22),
                spreadRadius: -18,
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < 5; i++)
                    i == 2
                        ? const SizedBox(width: 72, height: 54)
                        : Expanded(
                            child: _Tab(icon: icons[i], label: labels[i], on: current == i, onTap: () => onTap(i)),
                          ),
                ],
              ),
            ),
          ),
          // Measured off the prototype: the circle's top sits 8 px above the bar.
          Positioned(
            top: -8,
            left: 0,
            right: 0,
            child: Center(
              child: _CentreTab(label: labels[2], on: current == 2, onTap: () => onTap(2)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.icon, required this.label, required this.on, required this.onTap});
  final String icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = on ? Volt.accentInk : Volt.t3;
    return Semantics(
      selected: on,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.88,
        child: SizedBox(
          height: 54,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                top: -4,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  curve: voltEase,
                  width: on ? 18 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Volt.lime,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: on ? [BoxShadow(color: Volt.lime, blurRadius: 12)] : null,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedScale(
                    scale: on ? 1.1 : 1,
                    duration: const Duration(milliseconds: 280),
                    curve: voltEase,
                    child: VIcon(icon, size: 22, color: c),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.1,
                      height: 1,
                      color: c,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CentreTab extends StatelessWidget {
  const _CentreTab({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: on,
    button: true,
    label: label,
    excludeSemantics: true,
    child: Pressable(
      onTap: onTap,
      scale: 0.88,
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: Volt.glow,
          boxShadow: [
            BoxShadow(color: Volt.bg, spreadRadius: 6),
            BoxShadow(color: Color(0xD9B6F02A), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -8),
          ],
        ),
        child: const VIcon('dumb', size: 26, color: Volt.ink),
      ),
    ),
  );
}

/// `.toast`: a card that floats in above the tab bar.
OverlayEntry? _toast;

/// `.toast`: a short confirmation floating above the tabs. It never takes a
/// tap, so the keypad or list under it keeps working.
void showVToast(BuildContext context, String message, {bool info = false}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  if (_toast?.mounted ?? false) _toast!.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: 16,
      right: 16,
      bottom: 92 + MediaQuery.paddingOf(ctx).bottom,
      child: IgnorePointer(
        child: Semantics(
          liveRegion: true,
          // One animation is the toast's whole life: in, hold, out, gone.
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 2400),
            duration: const Duration(milliseconds: 2400),
            onEnd: () {
              if (_toast == entry) _toast = null;
              if (entry.mounted) entry.remove();
            },
            builder: (_, ms, child) {
              final t = const Cubic(0.22, 1, 0.36, 1).transform((ms / 380).clamp(0, 1));
              final out = ((2400 - ms) / 240).clamp(0.0, 1.0);
              return Opacity(
                opacity: t * out,
                child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child),
              );
            },
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  color: Volt.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Volt.line2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x80000000), blurRadius: 30, offset: Offset(0, 12), spreadRadius: -10),
                  ],
                ),
                child: Row(
                  children: [
                    VIcon(info ? 'info' : 'check', size: 17, color: info ? Volt.t3 : Volt.ok),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(message, style: TextStyle(fontSize: 13, color: Volt.t1)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _toast = entry;
  overlay.insert(entry);
}

// ---------------------------------------------------------------- keypad

/// `.keys`: the 3 × 4 number pad the serving editor and set editor use.
class Keypad extends StatelessWidget {
  const Keypad({super.key, required this.onKey, this.decimal = ',', this.deleteLabel = 'Delete'});

  /// Receives a digit, the [decimal] key, or `del`.
  final ValueChanged<String> onKey;
  final String decimal;
  final String deleteLabel;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', decimal, '0', 'del'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Volt.card,
        border: Border(top: BorderSide(color: Volt.line)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: LayoutBuilder(
        builder: (_, c) {
          final w = (c.maxWidth - 16) / 3;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in keys)
                SizedBox(
                  width: w,
                  child: Pressable(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onKey(k);
                    },
                    label: k == 'del' ? deleteLabel : k,
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Volt.card2, borderRadius: BorderRadius.circular(16)),
                      child: k == 'del'
                          ? VIcon('del', size: 22, color: Volt.t2)
                          : Text(
                              k,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: k == decimal ? Volt.t2 : Volt.t1,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- week strip

enum DayLook { normal, logged, future, planned }

class WeekDay {
  const WeekDay({
    required this.letter,
    required this.number,
    required this.label,
    this.look = DayLook.normal,
    this.dot = false,
    this.today = false,
  });
  final String letter;
  final int number;
  final String label;
  final DayLook look;
  final bool dot;
  final bool today;
}

/// `.week`: seven days, a ring around the one showing, dashed for days with a
/// log, dotted for planned ones, dim for the future.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.days, required this.selected, required this.onPick});
  final List<WeekDay> days;
  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
    child: Row(
      children: [
        for (var i = 0; i < days.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: _Day(day: days[i], on: i == selected, onTap: () => onPick(i)),
          ),
        ],
      ],
    ),
  );
}

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.on, required this.onTap});
  final WeekDay day;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final future = day.look == DayLook.future;
    final planned = day.look == DayLook.planned;
    final letterColor = on ? Volt.brandInk : (future ? Volt.t4 : Volt.t3);
    final numColor = on || day.today ? Volt.t1 : (future ? Volt.t4 : (planned ? Volt.t3 : Volt.t2));
    final numWeight = day.today ? FontWeight.w700 : (on ? FontWeight.w600 : FontWeight.w500);
    final ring = on
        ? _Ring(color: Volt.lime, width: 2)
        : switch (day.look) {
            DayLook.logged => _Ring(color: Volt.line2, width: 1.5, dash: 3.2),
            DayLook.planned => _Ring(color: Volt.line2, width: 1.5, dash: 1.4),
            _ => null,
          };
    return Semantics(
      button: true,
      selected: on,
      label: day.label,
      excludeSemantics: true,
      child: Pressable(
        onTap: onTap,
        scale: 0.9,
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              if (day.dot)
                Positioned(
                  top: -6,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: planned ? null : (on ? Volt.lime : Volt.t3),
                      border: planned ? Border.all(color: on ? Volt.lime : Volt.t4, width: 1.5) : null,
                    ),
                  ),
                ),
              Column(
                children: [
                  CustomPaint(
                    painter: ring,
                    child: SizedBox.square(
                      dimension: 34,
                      child: Center(
                        child: Text(
                          day.letter,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.13,
                            color: letterColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${day.number}',
                    style: numStyle(13, weight: numWeight, color: numColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  const _Ring({required this.color, required this.width, this.dash});
  final Color color;
  final double width;

  /// Dash length in px; null draws a solid ring.
  final double? dash;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = dash != null && dash! < 2 ? StrokeCap.round : StrokeCap.butt;
    final r = size.width / 2 - width / 2;
    final c = size.center(Offset.zero);
    if (dash == null) {
      canvas.drawCircle(c, r, p);
      return;
    }
    final circ = 2 * math.pi * r;
    final n = (circ / (dash! * 2.2)).floor();
    final step = 2 * math.pi / n;
    final sweep = step * (dash! < 2 ? 0.01 : 0.5);
    for (var i = 0; i < n; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * step, sweep, false, p);
    }
  }

  @override
  bool shouldRepaint(_Ring o) => o.color != color || o.width != width || o.dash != dash;
}

// ---------------------------------------------------------------- ways to log

class Method {
  const Method(this.id, this.label, this.icon);
  final String id;
  final String label;
  final String icon;
}

/// `.methods`: five peers in a row — Search, Write, Voice, Photo, Barcode.
class MethodRow extends StatelessWidget {
  const MethodRow({super.key, required this.methods, required this.current, required this.onPick});
  final List<Method> methods;
  final String current;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        for (final m in methods) ...[
          if (m != methods.first) const SizedBox(width: 8),
          Semantics(
            selected: m.id == current,
            child: Pressable(
              onTap: () => onPick(m.id),
              label: m.label,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 66,
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                decoration: BoxDecoration(
                  color: m.id == current ? Volt.brandWash : Volt.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: m.id == current ? Volt.lime : Volt.line),
                ),
                child: Column(
                  children: [
                    SizedBox.square(
                      dimension: 26,
                      child: Center(child: VIcon(m.icon, size: 21, color: m.id == current ? Volt.brandInk : Volt.t2)),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      m.label,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.11,
                        color: m.id == current ? Volt.brandInk : Volt.t2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ---------------------------------------------------------------- toggle

/// The settings toggle: 44 × 26, lime when on.
class VToggle extends StatelessWidget {
  const VToggle({super.key, required this.on});
  final bool on;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 44,
    height: 26,
    decoration: BoxDecoration(color: on ? Volt.brand : Volt.line2, borderRadius: BorderRadius.circular(999)),
    child: AnimatedAlign(
      duration: const Duration(milliseconds: 200),
      alignment: on ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        width: 20,
        height: 20,
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(shape: BoxShape.circle, color: on ? Colors.white : Volt.card),
      ),
    ),
  );
}

/// The dashed-box empty-state art used on Train, the builder and an empty workout.
class EmptyArt extends StatelessWidget {
  const EmptyArt({super.key, this.size = 60});
  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.string(
    '<svg viewBox="0 0 72 72" fill="none" xmlns="http://www.w3.org/2000/svg">'
    '<rect x="4" y="12" width="64" height="48" rx="14" stroke="#2A2E33" stroke-width="2" stroke-dasharray="6 7"/>'
    '<path d="M24 30v12M48 30v12M16 33v6M56 33v6M24 36h24" stroke="#5F665C" stroke-width="2.5" stroke-linecap="round"/></svg>',
    width: size,
    height: size,
  );
}

/// One macro on a dark tile: a coloured dot, its name, its grams.
class MacroTile extends StatelessWidget {
  const MacroTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.compact = false,
    this.sub,
  });
  final String label;
  final String value;
  final Color color;
  final bool compact;
  final String? sub;

  @override
  Widget build(BuildContext context) => Container(
    padding: compact ? const EdgeInsets.fromLTRB(12, 11, 10, 11) : const EdgeInsets.fromLTRB(14, 12, 12, 12),
    decoration: BoxDecoration(color: Volt.bg, borderRadius: BorderRadius.circular(14)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Volt.t3),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 4 : 5),
        Text(value, style: numStyle(compact ? 17 : 18)),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(
            sub!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: Volt.t3),
          ),
        ],
      ],
    ),
  );
}
