import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/catalog_seed.dart';
import '../../data/providers.dart';

class CartBar extends ConsumerWidget {
  const CartBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartSummaryProvider);
    final visible = summary.count > 0 || summary.hasSoldOut;
    final reduce = context.reduceMotion;
    return AnimatedSwitcher(
      duration: reduce ? BloomTokens.fast : BloomTokens.slow,
      switchInCurve: BloomTokens.easeEmphasized,
      transitionBuilder: (child, animation) {
        if (reduce) return FadeTransition(opacity: animation, child: child);
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.35),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: visible
          ? _Bar(key: const ValueKey('cart-bar'), summaryCount: summary.count)
          : const SizedBox(key: ValueKey('cart-bar-empty'), height: 0),
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({required this.summaryCount, super.key});

  final int summaryCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartSummaryProvider);
    final backend = ref.watch(backendProvider);
    final tokens = context.bloom;
    final label = summary.count == 1 ? '1 item' : '${summary.count} items';
    final goal = backend.store.freeDeliveryAbove;
    final progress = goal <= 0 ? 1.0 : (summary.subtotal / goal).clamp(0.0, 1.0);
    final thumbs = summary.lines.take(3).toList();
    return Material(
      color: tokens.surface,
      elevation: 8,
      shadowColor: const Color(0x1F0F1F17),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            minHeight: 3,
            value: progress,
            backgroundColor: tokens.border,
            color: tokens.discountBg,
          ),
          SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: thumbs.isEmpty ? 0 : 36.0 + (thumbs.length - 1) * 22,
                    height: 36,
                    child: Stack(
                      children: [
                        for (var i = 0; i < thumbs.length; i++)
                          Positioned(
                            left: i * 22.0,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: tokens.surface, width: 2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: ProductImage(
                                emoji: emojiFor(
                                  thumbs[i].product,
                                  backend.categories,
                                ),
                                kind: kindFor(thumbs[i].product, backend.categories),
                                url: thumbs[i].product.imageUrl,
                                bytes: backend.imageBytesFor(thumbs[i].product.id),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$label · ${money(summary.total)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BloomlyType.uiText(
                        14,
                        weight: FontWeight.w800,
                        color: tokens.text,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(96, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: BloomlyType.uiText(13, weight: FontWeight.w800),
                    ),
                    onPressed: () => context.push('/cart'),
                    child: const Text('View cart'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
