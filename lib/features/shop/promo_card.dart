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
    this.onTap,
    super.key,
  });

  final Story story;
  final bool compact;
  final bool dense;
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
      borderRadius: BorderRadius.circular(compact ? 16 : 18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: tap,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return switch (composition) {
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
              child: _Motif(motif: motif, color: accent),
            ),
            _copy(ink, compact: true),
          ],
        ),
      );
    }
    final motifSide = dense ? 64.0 : 76.0;
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
            child: _Motif(motif: motif, color: accent),
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
            child: _Motif(motif: motif, color: ink),
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
                  child: _Motif(motif: motif, color: accent),
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
                width: dense ? 40 : 52,
                height: dense ? 40 : 52,
                child: _Motif(motif: motif, color: accent),
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
            color: ink,
            fontWeight: FontWeight.w800,
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
  const _Motif({required this.motif, required this.color});

  final StoryMotif motif;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MotifPainter(motif: motif, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _MotifPainter extends CustomPainter {
  const _MotifPainter({required this.motif, required this.color});

  final StoryMotif motif;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    switch (motif) {
      case StoryMotif.neem:
        canvas.drawCircle(Offset(w * 0.72, h * 0.28), 7, paint);
        final leaf = Path()
          ..moveTo(w * 0.2, h * 0.75)
          ..quadraticBezierTo(w * 0.45, h * 0.15, w * 0.8, h * 0.55)
          ..quadraticBezierTo(w * 0.4, h * 0.7, w * 0.2, h * 0.75);
        canvas.drawPath(leaf, paint);
      case StoryMotif.cane:
        for (var i = 0; i < 3; i++) {
          final x = w * (0.28 + i * 0.18);
          canvas.drawLine(Offset(x, h * 0.15), Offset(x - 6, h * 0.85), stroke);
        }
        canvas.drawCircle(Offset(w * 0.72, h * 0.3), 10, paint);
      case StoryMotif.flower:
        final center = Offset(w * 0.5, h * 0.42);
        for (var i = 0; i < 5; i++) {
          final angle = i * 1.256;
          canvas.drawCircle(
            center + Offset(14 * math.cos(angle), 14 * math.sin(angle)),
            7,
            paint,
          );
        }
        canvas.drawCircle(
          center,
          5,
          Paint()..color = color.withValues(alpha: 0.45),
        );
      case StoryMotif.lamp:
        final flame = Path()
          ..moveTo(w * 0.5, h * 0.12)
          ..quadraticBezierTo(w * 0.78, h * 0.42, w * 0.5, h * 0.48)
          ..quadraticBezierTo(w * 0.22, h * 0.42, w * 0.5, h * 0.12);
        canvas.drawPath(flame, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(w * 0.32, h * 0.55, w * 0.36, h * 0.22),
            const Radius.circular(4),
          ),
          stroke,
        );
      case StoryMotif.leaf:
        final leaf = Path()
          ..moveTo(w * 0.2, h * 0.7)
          ..quadraticBezierTo(w * 0.55, h * 0.05, w * 0.82, h * 0.45)
          ..quadraticBezierTo(w * 0.45, h * 0.55, w * 0.2, h * 0.7);
        canvas.drawPath(leaf, paint);
      case StoryMotif.mango:
        final mango = Path()
          ..moveTo(w * 0.3, h * 0.55)
          ..quadraticBezierTo(w * 0.2, h * 0.15, w * 0.62, h * 0.22)
          ..quadraticBezierTo(w * 0.95, h * 0.35, w * 0.7, h * 0.78)
          ..quadraticBezierTo(w * 0.4, h * 0.9, w * 0.3, h * 0.55);
        canvas.drawPath(mango, paint);
      case StoryMotif.rain:
        for (var i = 0; i < 4; i++) {
          final x = w * (0.22 + i * 0.18);
          final y = h * (0.2 + (i.isEven ? 0.15 : 0));
          canvas.drawLine(Offset(x, y), Offset(x - 4, y + h * 0.28), stroke);
        }
      case StoryMotif.orange:
        canvas.drawCircle(Offset(w * 0.5, h * 0.48), w * 0.22, paint);
        canvas.drawCircle(
          Offset(w * 0.5, h * 0.22),
          4,
          Paint()..color = color.withValues(alpha: 0.7),
        );
      case StoryMotif.basket:
        final basket = Path()
          ..moveTo(w * 0.18, h * 0.4)
          ..lineTo(w * 0.82, h * 0.4)
          ..quadraticBezierTo(w * 0.78, h * 0.85, w * 0.5, h * 0.85)
          ..quadraticBezierTo(w * 0.22, h * 0.85, w * 0.18, h * 0.4);
        canvas.drawPath(basket, stroke);
        canvas.drawLine(
          Offset(w * 0.3, h * 0.4),
          Offset(w * 0.38, h * 0.2),
          stroke,
        );
        canvas.drawLine(
          Offset(w * 0.7, h * 0.4),
          Offset(w * 0.62, h * 0.2),
          stroke,
        );
      case StoryMotif.region:
        for (var i = 0; i < 4; i++) {
          canvas.drawCircle(
            Offset(w * (0.28 + (i % 2) * 0.36), h * (0.3 + (i ~/ 2) * 0.36)),
            8,
            paint,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _MotifPainter oldDelegate) {
    return oldDelegate.motif != motif || oldDelegate.color != color;
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
