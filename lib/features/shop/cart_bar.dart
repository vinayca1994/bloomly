import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/bloom_icons.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
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
          ? const _Bar(key: ValueKey('cart-bar'))
          : const SizedBox(key: ValueKey('cart-bar-empty'), height: 0),
    );
  }
}

class _Bar extends ConsumerWidget {
  const _Bar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(cartSummaryProvider);
    final tokens = context.bloom;
    final label = summary.count == 1 ? '1 item' : '${summary.count} items';
    return Semantics(
      button: true,
      label: 'View cart, $label, ${money(summary.total)}',
      child: Material(
        color: tokens.primary,
        child: InkWell(
          onTap: () => context.push('/cart'),
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'View cart',
                    style: BloomlyType.uiText(
                      15,
                      weight: FontWeight.w800,
                      color: tokens.onPrimary,
                    ),
                  ),
                  Icon(BloomIcons.caretRight, size: 18, color: tokens.onPrimary),
                  const Spacer(),
                  Text(
                    label,
                    style: BloomlyType.uiText(
                      13,
                      weight: FontWeight.w600,
                      color: tokens.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    money(summary.total),
                    style: BloomlyType.uiText(
                      15,
                      weight: FontWeight.w800,
                      color: tokens.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
