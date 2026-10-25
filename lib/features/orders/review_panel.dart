import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

class ReviewPanel extends ConsumerStatefulWidget {
  const ReviewPanel({required this.order, super.key});

  final OrderRecord order;

  @override
  ConsumerState<ReviewPanel> createState() => _ReviewPanelState();
}

class _ReviewPanelState extends ConsumerState<ReviewPanel> {
  final _note = TextEditingController();
  int _overall = 0;
  final _detail = <String, int>{};
  String? _error;
  bool _busy = false;
  var _showDetail = false;

  static const _aspects = <(String, String)>[
    ('freshness', 'Fresh'),
    ('rightItems', 'Right items'),
    ('packing', 'Well packed'),
    ('onTime', 'On time'),
    ('polite', 'Polite rider'),
    ('careful', 'Careful with the bag'),
  ];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int _score(String key) => _detail[key] ?? _overall;

  @override
  Widget build(BuildContext context) {
    final backend = ref.watch(backendProvider);
    final review = backend.reviewFor(widget.order.id);
    final user = backend.currentUser;
    final canWrite = review == null &&
        user != null &&
        user.id == widget.order.userId &&
        !user.isOwner &&
        !user.isRider &&
        widget.order.status == OrderStatus.delivered;
    if (review == null && !canWrite) return SizedBox.shrink();

    final tokens = context.bloom;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: DecoratedBox(
        decoration: BloomlyDecor.card(tokens),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: review != null
              ? _SavedReview(review: review)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How was your order?',
                      style: BloomlyType.display(16, weight: FontWeight.w600, color: tokens.text),
                    ),
                    const SizedBox(height: 8),
                    _OverallStars(
                      value: _overall,
                      onChanged: (value) => setState(() => _overall = value),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _showDetail = !_showDetail),
                      child: Text(_showDetail ? 'Hide detail' : 'Add detail'),
                    ),
                    if (_showDetail)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final aspect in _aspects)
                            FilterChip(
                              label: Text(aspect.$2),
                              selected: _detail.containsKey(aspect.$1),
                              onSelected: _overall == 0
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        if (selected) {
                                          _detail[aspect.$1] = _overall;
                                        } else {
                                          _detail.remove(aspect.$1);
                                        }
                                      });
                                    },
                            ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _note,
                      maxLength: 280,
                      decoration: const InputDecoration(labelText: 'Note (optional)'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(_error!, style: TextStyle(color: tokens.danger)),
                    ],
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _busy || _overall == 0 ? null : _submit,
                      child: const Text('Send review'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(backendProvider).submitReview(
      orderId: widget.order.id,
      freshness: _score('freshness'),
      rightItems: _score('rightItems'),
      packing: _score('packing'),
      onTime: _score('onTime'),
      polite: _score('polite'),
      careful: _score('careful'),
      note: _note.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
  }
}

class _SavedReview extends StatelessWidget {
  const _SavedReview({required this.review});

  final DeliveryReview review;

  @override
  Widget build(BuildContext context) {
    final scores = [
      review.freshness,
      review.rightItems,
      review.packing,
      review.onTime,
      review.polite,
      review.careful,
    ];
    final overall = (scores.reduce((a, b) => a + b) / scores.length).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your review',
          style: BloomlyType.display(16, weight: FontWeight.w600, color: context.bloom.text),
        ),
        const SizedBox(height: 8),
        _OverallStars(value: overall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final row in [
              ('Fresh', review.freshness),
              ('Right items', review.rightItems),
              ('Well packed', review.packing),
              ('On time', review.onTime),
              ('Polite rider', review.polite),
              ('Careful with the bag', review.careful),
            ])
              Chip(label: Text('${row.$1} ${row.$2}')),
          ],
        ),
        if (review.note.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(review.note),
        ],
      ],
    );
  }
}

class RiderScoreList extends StatelessWidget {
  const RiderScoreList({required this.review, super.key});

  final DeliveryReview review;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(label: Text('On time ${review.onTime}')),
        Chip(label: Text('Polite ${review.polite}')),
        Chip(label: Text('Careful ${review.careful}')),
      ],
    );
  }
}

class _OverallStars extends StatelessWidget {
  const _OverallStars({required this.value, this.onChanged});

  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.bloom;
    return Row(
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            tooltip: '$star star${star == 1 ? '' : 's'}',
            onPressed: onChanged == null ? null : () => onChanged!(star),
            icon: Icon(
              star <= value ? Icons.star : Icons.star_border,
              color: tokens.star,
              size: 32,
            ),
          ),
      ],
    );
  }
}
