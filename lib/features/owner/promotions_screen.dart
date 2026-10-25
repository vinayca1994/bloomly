import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/promo_templates.dart';
import '../../data/providers.dart';
import '../../data/stories.dart';
import '../shop/promo_card.dart';
import '../shop/story_style.dart';

class PromotionsScreen extends ConsumerWidget {
  const PromotionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final backend = ref.watch(backendProvider);
    final banners = [...backend.store.promotions]
      ..sort((a, b) => a.sort.compareTo(b.sort));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Promotions', style: BloomlyType.display(28)),
        const SizedBox(height: 6),
        Text(
          'A banner shows on Home only after you publish it, and only between its dates.',
          style: TextStyle(color: context.bloom.textSecondary),
        ),
        const SizedBox(height: 16),
        if (banners.isEmpty)
          const Text('Nothing published yet.')
        else
          for (var index = 0; index < banners.length; index++)
            _BannerRow(
              story: banners[index],
              canUp: index > 0,
              canDown: index < banners.length - 1,
              onUp: () => _move(ref, banners, index, -1),
              onDown: () => _move(ref, banners, index, 1),
              onHide: () => _replace(
                ref,
                banners[index].copyWith(hidden: !banners[index].hidden),
              ),
              onEdit: () =>
                  context.push('/owner/promotions/edit', extra: banners[index]),
              onRemove: () => _remove(ref, banners[index].id),
            ),
        const SizedBox(height: 28),
        Text('Templates', style: BloomlyType.display(22)),
        const SizedBox(height: 6),
        Text(
          'Pick one to edit, then publish. Home stays unchanged until then.',
          style: TextStyle(color: context.bloom.textSecondary),
        ),
        for (final category in promoCategories) ...[
          const SizedBox(height: 16),
          Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          for (final template in promoTemplates)
            if (template.category == category)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openTemplate(context, ref, template),
                    child: Ink(
                      decoration: BloomlyDecor.card(context.bloom, radius: 16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 36,
                              decoration: BoxDecoration(
                                color: StoryPalette.of(template.tone).wash,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    template.subtitle,
                                    style: TextStyle(
                                      color: context.bloom.textSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.add,
                              color: context.bloom.link,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ],
    );
  }

  void _openTemplate(
    BuildContext context,
    WidgetRef ref,
    PromoTemplate template,
  ) {
    final current = ref.read(backendProvider).store.promotions;
    final used = current.map((story) => story.id).toSet();
    var id = template.id;
    var n = 2;
    while (used.contains(id)) {
      id = '${template.id}-$n';
      n++;
    }
    final sort = current.fold<int>(
      0,
      (max, story) => story.sort > max ? story.sort : max,
    );
    context.push(
      '/owner/promotions/edit',
      extra: template.story(id: id, sort: current.isEmpty ? 0 : sort + 1),
    );
  }

  Future<void> _replace(WidgetRef ref, Story next) async {
    final current = ref.read(backendProvider).store.promotions;
    await _save(ref, [
      for (final story in current)
        if (story.id == next.id) next else story,
    ]);
  }

  Future<void> _remove(WidgetRef ref, String id) async {
    final current = ref.read(backendProvider).store.promotions;
    await _save(ref, [
      for (final story in current)
        if (story.id != id) story,
    ]);
  }

  Future<void> _move(
    WidgetRef ref,
    List<Story> banners,
    int index,
    int delta,
  ) async {
    final nextIndex = index + delta;
    final swapped = [...banners];
    final item = swapped.removeAt(index);
    swapped.insert(nextIndex, item);
    await _save(ref, [
      for (var i = 0; i < swapped.length; i++) swapped[i].copyWith(sort: i),
    ]);
  }

  Future<void> _save(WidgetRef ref, List<Story> next) async {
    final backend = ref.read(backendProvider);
    await backend.updateStore(backend.store.copyWith(promotions: next));
  }
}

class _BannerRow extends StatelessWidget {
  const _BannerRow({
    required this.story,
    required this.canUp,
    required this.canDown,
    required this.onUp,
    required this.onDown,
    required this.onHide,
    required this.onEdit,
    required this.onRemove,
  });

  final Story story;
  final bool canUp;
  final bool canDown;
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onHide;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final live = story.isActiveAt(DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BloomlyDecor.card(context.bloom, radius: 16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: StoryPalette.of(story.tone).wash,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      story.title,
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  Text(
                    live ? 'On Home' : (story.hidden ? 'Hidden' : 'Scheduled'),
                    style: TextStyle(
                      color: live
                          ? context.bloom.link
                          : context.bloom.textSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                story.subtitle,
                style: TextStyle(color: context.bloom.textSecondary),
              ),
              Text(
                _when(story),
                style: TextStyle(
                  color: context.bloom.textSecondary,
                  fontSize: 12,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Move up',
                    onPressed: canUp ? onUp : null,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    tooltip: 'Move down',
                    onPressed: canDown ? onDown : null,
                    icon: const Icon(Icons.arrow_downward),
                  ),
                  TextButton(
                    onPressed: onHide,
                    child: Text(story.hidden ? 'Show' : 'Hide'),
                  ),
                  TextButton(onPressed: onEdit, child: const Text('Edit')),
                  TextButton(
                    onPressed: onRemove,
                    child: Text(
                      'Remove',
                      style: TextStyle(color: context.bloom.danger),
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

class PromotionEditor extends ConsumerStatefulWidget {
  const PromotionEditor({required this.draft, super.key});

  final Story? draft;

  @override
  ConsumerState<PromotionEditor> createState() => _PromotionEditorState();
}

class _PromotionEditorState extends ConsumerState<PromotionEditor> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _eyebrow;
  late StoryTone _tone;
  late StoryPlacement _placement;
  late String _styleId;
  late String _route;
  DateTime? _start;
  DateTime? _end;
  String? _error;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _title = TextEditingController(text: draft?.title ?? '');
    _subtitle = TextEditingController(text: draft?.subtitle ?? '');
    _eyebrow = TextEditingController(text: draft?.eyebrow ?? '');
    _tone = draft?.tone ?? StoryTone.leaf;
    _placement = draft?.placement ?? StoryPlacement.homeBanner;
    _styleId = draft?.styleId ?? '';
    final styles = promoStyles(draft?.themeId ?? '');
    if (_styleId.isEmpty && styles.isNotEmpty) _styleId = styles.first.id;
    _route = draft?.route ?? '';
    _start = draft?.startsAt;
    _end = _shownEnd(draft?.endsAt);
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _eyebrow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Scaffold(
      appBar: AppBar(title: Text(draft == null ? 'Banner' : 'Edit banner')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (draft == null)
            const Text('Open a template from Promotions.')
          else ...[
            TextField(
              controller: _eyebrow,
              decoration: const InputDecoration(labelText: 'Eyebrow'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _subtitle,
              decoration: const InputDecoration(labelText: 'Subtitle'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Publish on',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final placement in StoryPlacement.values)
                  ChoiceChip(
                    label: Text(_placementLabel(placement)),
                    selected: _placement == placement,
                    onSelected: (_) => setState(() {
                      _placement = placement;
                      if (placement == StoryPlacement.category &&
                          !promoAisles.any((item) => item.$2 == _route)) {
                        _route = promoAisles.first.$2;
                      }
                    }),
                  ),
              ],
            ),
            if (promoStyles(draft.themeId).isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Style',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final style in promoStyles(draft.themeId))
                    ChoiceChip(
                      label: Text(style.name),
                      selected: _styleId == style.id,
                      onSelected: (_) => setState(() => _styleId = style.id),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              key: ValueKey('$_placement|$_route'),
              initialValue: _placement == StoryPlacement.category
                  ? (promoAisles.any((item) => item.$2 == _route)
                        ? _route
                        : promoAisles.first.$2)
                  : (promoDestinations.any((item) => item.$2 == _route)
                        ? _route
                        : ''),
              decoration: InputDecoration(
                labelText: _placement == StoryPlacement.category
                    ? 'Aisle'
                    : 'Opens',
              ),
              items: [
                if (_placement != StoryPlacement.category)
                  const DropdownMenuItem(value: '', child: Text('Nowhere')),
                for (final destination
                    in _placement == StoryPlacement.category
                        ? promoAisles
                        : promoDestinations)
                  DropdownMenuItem(
                    value: destination.$2,
                    child: Text(destination.$1),
                  ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _route = value);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: _placement == StoryPlacement.homeClip
                  ? 180
                  : _placement == StoryPlacement.category
                  ? 112
                  : 156,
              child: PromoCard(
                story: draft.copyWith(
                  title: _title.text,
                  subtitle: _subtitle.text,
                  eyebrow: _eyebrow.text,
                  placement: _placement,
                  styleId: _styleId,
                  motif: promoStyle(draft.themeId, _styleId)?.motif,
                  route: _route,
                ),
                compact: _placement == StoryPlacement.homeClip,
              ),
            ),
            const SizedBox(height: 16),
            _dateRow(
              label: 'Starts',
              day: _start,
              onPick: (day) => setState(() => _start = day),
              onClear: () => setState(() => _start = null),
            ),
            _dateRow(
              label: 'Ends',
              day: _end,
              onPick: (day) => setState(() => _end = day),
              onClear: () => setState(() => _end = null),
            ),
            if (_error != null) ...[
              SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: context.bloom.danger),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _publish, child: const Text('Publish')),
          ],
        ],
      ),
    );
  }

  Widget _dateRow({
    required String label,
    required DateTime? day,
    required ValueChanged<DateTime> onPick,
    required VoidCallback onClear,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            day == null ? '$label: any day' : '$label: ${_dayLabel(day)}',
          ),
        ),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: day ?? DateTime.now(),
              firstDate: DateTime(2024),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              onPick(DateTime(picked.year, picked.month, picked.day));
            }
          },
          child: const Text('Set'),
        ),
        if (day != null)
          TextButton(onPressed: onClear, child: const Text('Clear')),
      ],
    );
  }

  Future<void> _publish() async {
    final draft = widget.draft;
    final title = _title.text.trim();
    if (draft == null || title.isEmpty) {
      setState(() => _error = 'Add a title.');
      return;
    }
    final story = Story(
      id: draft.id,
      placement: _placement,
      title: title,
      subtitle: _subtitle.text.trim(),
      tone: _tone,
      themeId: draft.themeId,
      styleId: _styleId,
      eyebrow: _eyebrow.text.trim(),
      motif: promoStyle(draft.themeId, _styleId)?.motif ?? draft.motif,
      route: _route.isEmpty ? null : _route,
      sort: draft.sort,
      hidden: false,
      startsAt: _start,
      endsAt: _end == null ? null : _exclusiveEnd(_end!),
    );
    final backend = ref.read(backendProvider);
    final current = [...backend.store.promotions];
    final index = current.indexWhere((item) => item.id == story.id);
    if (index >= 0) {
      current[index] = story;
    } else {
      current.add(story);
    }
    try {
      await backend.updateStore(backend.store.copyWith(promotions: current));
    } on BloomlyException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not publish. Try again.');
      return;
    }
    if (mounted) context.pop();
  }
}

String _placementLabel(StoryPlacement placement) {
  return switch (placement) {
    StoryPlacement.homeBanner => 'Home',
    StoryPlacement.homeClip => 'Clips',
    StoryPlacement.category => 'Category',
    StoryPlacement.splash => 'Splash',
  };
}

String _when(Story story) {
  final start = story.startsAt;
  final end = _shownEnd(story.endsAt);
  if (start == null && end == null) return 'Any day';
  if (start != null && end != null) {
    return '${_dayLabel(start)} – ${_dayLabel(end)}';
  }
  if (start != null) return 'From ${_dayLabel(start)}';
  return 'Until ${_dayLabel(end!)}';
}

DateTime? _shownEnd(DateTime? exclusive) {
  if (exclusive == null) return null;
  final previous = exclusive.subtract(const Duration(days: 1));
  return DateTime(previous.year, previous.month, previous.day);
}

DateTime _exclusiveEnd(DateTime day) {
  final next = DateTime(day.year, day.month, day.day + 1);
  return DateTime(next.year, next.month, next.day);
}

String _dayLabel(DateTime day) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${day.day} ${months[day.month - 1]} ${day.year}';
}
