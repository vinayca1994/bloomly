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
  int _freshness = 0;
  int _rightItems = 0;
  int _packing = 0;
  int _onTime = 0;
  int _polite = 0;
  int _careful = 0;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

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
    if (review == null && !canWrite) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text('Review', style: BloomlyType.display(22)),
        const SizedBox(height: 8),
        if (review != null)
          _SavedReview(review: review)
        else ...[
          Text('Items', style: BloomlyType.display(16)),
          _Stars(label: 'Freshness', value: _freshness, onChanged: (value) => setState(() => _freshness = value)),
          _Stars(label: 'Right items', value: _rightItems, onChanged: (value) => setState(() => _rightItems = value)),
          _Stars(label: 'Packing', value: _packing, onChanged: (value) => setState(() => _packing = value)),
          const SizedBox(height: 8),
          Text('Rider${widget.order.riderName.isEmpty ? '' : ' · ${widget.order.riderName}'}', style: BloomlyType.display(16)),
          _Stars(label: 'On time', value: _onTime, onChanged: (value) => setState(() => _onTime = value)),
          _Stars(label: 'Polite', value: _polite, onChanged: (value) => setState(() => _polite = value)),
          _Stars(label: 'Careful with the bag', value: _careful, onChanged: (value) => setState(() => _careful = value)),
          const SizedBox(height: 8),
          TextField(
            controller: _note,
            maxLength: 280,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: BloomlyColors.danger)),
          ],
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: const Text('Send review'),
          ),
        ],
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await ref.read(backendProvider).submitReview(
      orderId: widget.order.id,
      freshness: _freshness,
      rightItems: _rightItems,
      packing: _packing,
      onTime: _onTime,
      polite: _polite,
      careful: _careful,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Items', style: BloomlyType.display(16)),
        _Stars(label: 'Freshness', value: review.freshness),
        _Stars(label: 'Right items', value: review.rightItems),
        _Stars(label: 'Packing', value: review.packing),
        const SizedBox(height: 8),
        Text('Rider', style: BloomlyType.display(16)),
        _Stars(label: 'On time', value: review.onTime),
        _Stars(label: 'Polite', value: review.polite),
        _Stars(label: 'Careful with the bag', value: review.careful),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Stars(label: 'On time', value: review.onTime),
        _Stars(label: 'Polite', value: review.polite),
        _Stars(label: 'Careful with the bag', value: review.careful),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.label, required this.value, this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 132, child: Text(label, style: const TextStyle(fontSize: 14))),
        for (var star = 1; star <= 5; star++)
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onChanged == null ? null : () => onChanged!(star),
            icon: Icon(
              star <= value ? Icons.star : Icons.star_border,
              color: BloomlyColors.marigold,
              size: 22,
            ),
          ),
      ],
    );
  }
}
