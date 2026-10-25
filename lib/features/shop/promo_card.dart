import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/promo_templates.dart';
import '../../data/stories.dart';
import 'story_style.dart';

class PromoCard extends StatelessWidget {
  const PromoCard({
    required this.story,
    this.compact = false,
    this.dense = false,
    this.bleed = false,
    this.onTap,
    super.key,
  });

  final Story story;
  final bool compact;
  final bool dense;

  /// Full-bleed splash: no radius, art fills the frame.
  final bool bleed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final look = promoLook(story.themeId);
    final palette = StoryPalette.of(story.tone);
    final ground = look?.ground ?? palette.wash;
    final ink = look?.ink ?? palette.title;
    final accent = look?.accent ?? palette.subtitle;
    final style = promoStyle(story.themeId, story.styleId);
    final motif = style?.motif ?? look?.motif ?? story.motif;
    final composition = style?.composition ?? PromoComposition.poster;
    final route = story.route;
    final tap = onTap ?? (route == null ? null : () => context.go(route));
    return Material(
      color: ground,
      borderRadius: BorderRadius.circular(bleed ? 0 : (compact ? 16 : 18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final body = switch (composition) {
              PromoComposition.stack => _stack(constraints, ink, accent, motif),
              PromoComposition.ticket => _ticket(
                constraints,
                ink,
                accent,
                motif,
              ),
              PromoComposition.poster => _poster(
                constraints,
                ink,
                accent,
                motif,
              ),
            };
            if (!bleed) return body;
            return SizedBox.expand(child: body);
          },
        ),
      ),
    );
  }

  Widget _poster(
    BoxConstraints constraints,
    Color ink,
    Color accent,
    StoryMotif motif,
  ) {
    final pad = EdgeInsets.all(compact ? 12 : (dense ? 14 : 16));
    if (compact) {
      return Padding(
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _Motif(motif: motif, ink: ink, accent: accent),
            ),
            _copy(ink, compact: true),
          ],
        ),
      );
    }
    final innerHeight = constraints.maxHeight.isFinite
        ? math.max(48.0, constraints.maxHeight - pad.vertical)
        : 120.0;
    final motifSide = constraints.maxHeight > 400
        ? math.min(constraints.maxWidth * 0.72, constraints.maxHeight * 0.5)
        : math.min(dense ? 96.0 : 120.0, innerHeight);
    final copy = _copy(ink, compact: false, dense: dense);
    final textWidth = math.max(
      0.0,
      constraints.maxWidth - motifSide - 12 - pad.horizontal,
    );
    return Padding(
      padding: pad,
      child: Row(
        children: [
          Expanded(
            child: constraints.maxHeight.isFinite
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(width: textWidth, child: copy),
                  )
                : copy,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: motifSide,
            height: motifSide,
            child: _Motif(motif: motif, ink: ink, accent: accent),
          ),
        ],
      ),
    );
  }

  Widget _stack(
    BoxConstraints constraints,
    Color ink,
    Color accent,
    StoryMotif motif,
  ) {
    final bandHeight = compact
        ? 72.0
        : math.min(
            64.0,
            constraints.maxHeight.isFinite
                ? constraints.maxHeight * 0.42
                : 64.0,
          );
    final band = ColoredBox(
      color: accent,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: compact ? 56 : 48,
            height: compact ? 56 : 48,
            child: _Motif(
              motif: motif,
              ink: ink,
              accent: Color.alphaBlend(const Color(0x66FFFFFF), ink),
            ),
          ),
        ),
      ),
    );
    final copy = Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 12 : 16,
        10,
        compact ? 12 : 16,
        compact ? 12 : 14,
      ),
      child: _copy(ink, compact: compact, dense: dense),
    );
    if (!constraints.maxHeight.isFinite) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: bandHeight, child: band),
          copy,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: bandHeight, child: band),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: SizedBox(width: constraints.maxWidth, child: copy),
          ),
        ),
      ],
    );
  }

  Widget _ticket(
    BoxConstraints constraints,
    Color ink,
    Color accent,
    StoryMotif motif,
  ) {
    final copy = _copy(ink, compact: compact, dense: dense || compact);
    final body = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: _Motif(motif: motif, ink: ink, accent: accent),
                ),
              ),
              const Spacer(),
              copy,
            ],
          )
        : Row(
            children: [
              Expanded(child: copy),
              SizedBox(
                width: dense ? 56 : 72,
                height: dense ? 56 : 72,
                child: _Motif(motif: motif, ink: ink, accent: accent),
              ),
            ],
          );
    final framed = Padding(
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        painter: _DashPainter(color: accent),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            12,
            compact ? 8 : 10,
            12,
            compact ? 8 : 10,
          ),
          child: body,
        ),
      ),
    );
    if (!constraints.maxHeight.isFinite) return framed;
    return SizedBox.expand(child: framed);
  }

  Widget _copy(Color ink, {required bool compact, bool dense = false}) {
    final eyebrow = story.eyebrow.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: compact
          ? MainAxisAlignment.end
          : MainAxisAlignment.center,
      children: [
        if (eyebrow.isNotEmpty)
          Text(
            eyebrow.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink.withValues(alpha: 0.72),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              height: 1.1,
            ),
          ),
        Text(
          story.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'BricolageGrotesque',
            color: ink,
            fontWeight: FontWeight.w700,
            fontSize: compact ? 15 : (dense ? 18 : 20),
            height: 1.15,
          ),
        ),
        if (!compact && story.subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            story.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
              fontSize: dense ? 12 : 13,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _Motif extends StatelessWidget {
  const _Motif({required this.motif, required this.ink, required this.accent});

  final StoryMotif motif;
  final Color ink;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MotifPainter(motif: motif, ink: ink, accent: accent),
      child: const SizedBox.expand(),
    );
  }
}

class _MotifPainter extends CustomPainter {
  const _MotifPainter({
    required this.motif,
    required this.ink,
    required this.accent,
  });

  final StoryMotif motif;
  final Color ink;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    final fg = _fill(ink);
    final ac = _fill(accent);
    switch (motif) {
      case StoryMotif.neem:
        _ugadi(canvas, fg, ac);
      case StoryMotif.cane:
        _sankranti(canvas, fg, ac);
      case StoryMotif.flower:
        _ganesh(canvas, fg, ac);
      case StoryMotif.lamp:
        _diwali(canvas, fg, ac);
      case StoryMotif.leaf:
        _onam(canvas, fg, ac);
      case StoryMotif.orange:
        _wreath(canvas, fg, ac);
      case StoryMotif.mango:
        _summer(canvas, fg, ac);
      case StoryMotif.rain:
        _monsoon(canvas, fg, ac);
      case StoryMotif.basket:
        _basket(canvas, fg, ac);
      case StoryMotif.region:
        _region(canvas, fg, ac);
    }
    canvas.restore();
  }

  Paint _fill(Color color, [double opacity = 1]) {
    return Paint()..color = color.withValues(alpha: opacity);
  }

  Paint _stroke(Color color, double width) {
    return Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  void _ugadi(Canvas canvas, Paint fg, Paint ac) {
    canvas.drawLine(const Offset(0, 10), const Offset(100, 10), _stroke(accent, 3));
    for (var i = 0; i < 7; i++) {
      final x = 2.0 + i * 16;
      final flag = Path()
        ..moveTo(x, 10)
        ..lineTo(x + 7, 32)
        ..lineTo(x + 14, 10)
        ..close();
      canvas.drawPath(flag, i.isEven ? fg : ac);
    }
    canvas.drawCircle(const Offset(62, 68), 22, ac);
    final leaf = Path()
      ..moveTo(40, 90)
      ..relativeCubicTo(8, -30, 30, -40, 50, -40)
      ..relativeCubicTo(-6, 24, -26, 40, -50, 40)
      ..close();
    canvas.drawPath(leaf, fg);
  }

  void _sankranti(Canvas canvas, Paint fg, Paint ac) {
    final kite = Path()
      ..moveTo(50, 6)
      ..lineTo(84, 44)
      ..lineTo(50, 82)
      ..lineTo(16, 44)
      ..close();
    canvas.drawPath(kite, ac);
    final spine = _stroke(ink, 2);
    canvas.drawLine(const Offset(50, 6), const Offset(50, 82), spine);
    canvas.drawLine(const Offset(16, 44), const Offset(84, 44), spine);
    final tail = Path()
      ..moveTo(50, 82)
      ..relativeCubicTo(-6, 8, 6, 10, 0, 18);
    canvas.drawPath(tail, spine);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(80, 40, 5, 60),
        const Radius.circular(2),
      ),
      _fill(ink, 0.6),
    );
  }

  void _ganesh(Canvas canvas, Paint fg, Paint ac) {
    for (var i = 0; i < 9; i++) {
      canvas.drawCircle(Offset(5.0 + i * 11, 8), 5, i.isEven ? ac : fg);
    }
    final modak = Path()
      ..moveTo(50, 14)
      ..relativeCubicTo(14, 22, 30, 34, 30, 52)
      ..arcToPoint(const Offset(20, 66), radius: const Radius.circular(30))
      ..relativeCubicTo(0, -18, 16, -30, 30, -52)
      ..close();
    canvas.drawPath(modak, ac);
    final smile = _stroke(ink, 3);
    canvas.drawPath(
      Path()
        ..moveTo(36, 56)
        ..quadraticBezierTo(50, 66, 64, 56),
      smile,
    );
    canvas.drawPath(
      Path()
        ..moveTo(30, 70)
        ..quadraticBezierTo(50, 82, 70, 70),
      smile,
    );
  }

  void _diwali(Canvas canvas, Paint fg, Paint ac) {
    canvas.drawCircle(const Offset(50, 54), 40, _fill(accent, 0.22));
    final flame = Path()
      ..moveTo(50, 22)
      ..relativeCubicTo(10, 14, 10, 24, 0, 30)
      ..relativeCubicTo(-10, -6, -10, -16, 0, -30)
      ..close();
    canvas.drawPath(flame, ac);
    final bowl = Path()
      ..moveTo(18, 62)
      ..lineTo(82, 62)
      ..arcToPoint(
        const Offset(18, 62),
        radius: const Radius.elliptical(32, 22),
        clockwise: true,
      );
    canvas.drawPath(bowl, fg);
  }

  void _onam(Canvas canvas, Paint fg, Paint ac) {
    const rings = [46.0, 36.0, 26.0, 16.0, 7.0];
    for (var i = 0; i < rings.length; i++) {
      canvas.drawCircle(const Offset(50, 50), rings[i], i.isEven ? ac : fg);
    }
  }

  void _wreath(Canvas canvas, Paint fg, Paint ac) {
    canvas.drawCircle(const Offset(50, 50), 36, _stroke(accent, 12));
    for (var t = 0; t < 8; t++) {
      final angle = t / 8 * math.pi * 2;
      canvas.drawCircle(
        Offset(50 + 36 * math.cos(angle), 50 + 36 * math.sin(angle)),
        6,
        fg,
      );
    }
  }

  void _summer(Canvas canvas, Paint fg, Paint ac) {
    canvas.drawOval(const Rect.fromLTWH(18, 14, 68, 80), _fill(accent, 0.9));
    canvas.drawOval(const Rect.fromLTWH(30, 26, 44, 56), _fill(ink, 0.18));
    final leaf = Path()
      ..moveTo(58, 14)
      ..relativeCubicTo(8, -8, 18, -8, 22, -4)
      ..relativeCubicTo(-8, 2, -14, 6, -22, 4)
      ..close();
    canvas.drawPath(leaf, fg);
    final wave = _stroke(accent, 3);
    for (final y in [86.0, 94.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(6, y)
          ..relativeQuadraticBezierTo(6, -5, 12, 0)
          ..relativeQuadraticBezierTo(6, 5, 12, 0),
        wave,
      );
    }
  }

  void _monsoon(Canvas canvas, Paint fg, Paint ac) {
    final drop = _stroke(ink, 3);
    const drops = <Offset>[
      Offset(20, 6),
      Offset(44, 0),
      Offset(70, 10),
      Offset(92, 2),
      Offset(32, 30),
      Offset(58, 26),
      Offset(84, 34),
    ];
    for (final start in drops) {
      canvas.drawLine(start, start + const Offset(-8, 18), drop);
    }
    final leaf = Path()
      ..moveTo(14, 98)
      ..cubicTo(14, 70, 34, 56, 62, 56)
      ..relativeCubicTo(0, 26, -20, 42, -48, 42)
      ..close();
    canvas.drawPath(leaf, ac);
    canvas.drawLine(const Offset(14, 98), const Offset(50, 66), _stroke(ink, 2));
  }

  void _basket(Canvas canvas, Paint fg, Paint ac) {
    canvas.drawCircle(const Offset(38, 34), 12, ac);
    canvas.drawCircle(const Offset(58, 30), 14, fg);
    canvas.drawCircle(const Offset(74, 40), 10, ac);
    final basket = Path()
      ..moveTo(16, 48)
      ..lineTo(84, 48)
      ..quadraticBezierTo(80, 92, 50, 92)
      ..quadraticBezierTo(20, 92, 16, 48)
      ..close();
    canvas.drawPath(basket, fg);
    canvas.drawLine(const Offset(22, 62), const Offset(78, 62), _stroke(accent, 2));
    canvas.drawLine(const Offset(28, 74), const Offset(74, 74), _stroke(accent, 2));
    final handle = Path()
      ..moveTo(30, 48)
      ..quadraticBezierTo(32, 16, 50, 14)
      ..quadraticBezierTo(68, 16, 70, 48);
    canvas.drawPath(handle, _stroke(ink, 3));
  }

  void _region(Canvas canvas, Paint fg, Paint ac) {
    canvas.drawCircle(const Offset(50, 50), 34, ac);
    canvas.drawCircle(const Offset(50, 50), 22, fg);
    canvas.drawCircle(const Offset(50, 50), 10, ac);
    for (var i = 0; i < 6; i++) {
      final angle = i / 6 * math.pi * 2;
      canvas.drawCircle(
        Offset(50 + 28 * math.cos(angle), 50 + 28 * math.sin(angle)),
        6,
        i.isEven ? fg : ac,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MotifPainter oldDelegate) {
    return oldDelegate.motif != motif ||
        oldDelegate.ink != ink ||
        oldDelegate.accent != accent;
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(12),
        ).deflate(1),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + 7, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
