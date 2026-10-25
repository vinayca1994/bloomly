import 'dart:convert';

enum StoryPlacement { homeBanner, homeClip, category, splash }

enum StoryTone { leaf, fruit, flower, marigold }

enum StoryMotif {
  neem,
  cane,
  flower,
  lamp,
  leaf,
  mango,
  rain,
  orange,
  basket,
  region,
}

class Story {
  const Story({
    required this.id,
    required this.placement,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.sort,
    this.route,
    this.themeId = '',
    this.styleId = '',
    this.eyebrow = '',
    this.motif = StoryMotif.leaf,
    this.hidden = false,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final StoryPlacement placement;
  final String title;
  final String subtitle;
  final String? route;
  final String themeId;
  final String styleId;
  final String eyebrow;
  final StoryMotif motif;
  final StoryTone tone;
  final int sort;
  final bool hidden;

  /// Inclusive start, stored as local midnight. [endsAt] is exclusive.
  final DateTime? startsAt;
  final DateTime? endsAt;

  bool isActiveAt(DateTime now) {
    if (hidden) return false;
    final starts = startsAt;
    final ends = endsAt;
    if (starts != null && now.isBefore(starts)) return false;
    if (ends != null && !now.isBefore(ends)) return false;
    return true;
  }

  Story copyWith({
    String? title,
    String? subtitle,
    StoryTone? tone,
    String? route,
    StoryPlacement? placement,
    String? themeId,
    String? styleId,
    String? eyebrow,
    StoryMotif? motif,
    int? sort,
    bool? hidden,
    DateTime? startsAt,
    DateTime? endsAt,
    bool clearStart = false,
    bool clearEnd = false,
  }) {
    return Story(
      id: id,
      placement: placement ?? this.placement,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      tone: tone ?? this.tone,
      route: route ?? this.route,
      themeId: themeId ?? this.themeId,
      styleId: styleId ?? this.styleId,
      eyebrow: eyebrow ?? this.eyebrow,
      motif: motif ?? this.motif,
      sort: sort ?? this.sort,
      hidden: hidden ?? this.hidden,
      startsAt: clearStart ? null : (startsAt ?? this.startsAt),
      endsAt: clearEnd ? null : (endsAt ?? this.endsAt),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'placement': placement.name,
    'title': title,
    'subtitle': subtitle,
    'tone': tone.name,
    'themeId': themeId,
    'styleId': styleId,
    'eyebrow': eyebrow,
    'motif': motif.name,
    'route': route ?? '',
    'sort': sort,
    'hidden': hidden,
    'startsAt': startsAt?.toIso8601String() ?? '',
    'endsAt': endsAt?.toIso8601String() ?? '',
  };

  static Story? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final title = raw['title'];
    if (id is! String || id.isEmpty || title is! String || title.isEmpty) {
      return null;
    }
    return Story(
      id: id,
      placement: _placement(raw['placement']),
      title: title,
      subtitle: raw['subtitle'] is String ? raw['subtitle'] as String : '',
      tone: _tone(raw['tone']),
      themeId: raw['themeId'] is String ? raw['themeId'] as String : '',
      styleId: raw['styleId'] is String ? raw['styleId'] as String : '',
      eyebrow: raw['eyebrow'] is String ? raw['eyebrow'] as String : '',
      motif: _motif(raw['motif']),
      route: raw['route'] is String && (raw['route'] as String).isNotEmpty
          ? raw['route'] as String
          : null,
      sort: raw['sort'] is int ? raw['sort'] as int : 0,
      hidden: raw['hidden'] == true,
      startsAt: _time(raw['startsAt']),
      endsAt: _time(raw['endsAt']),
    );
  }
}

StoryPlacement _placement(Object? raw) {
  for (final placement in StoryPlacement.values) {
    if (placement.name == raw) return placement;
  }
  return StoryPlacement.homeBanner;
}

StoryMotif _motif(Object? raw) {
  for (final motif in StoryMotif.values) {
    if (motif.name == raw) return motif;
  }
  return StoryMotif.leaf;
}

StoryTone _tone(Object? raw) {
  for (final tone in StoryTone.values) {
    if (tone.name == raw) return tone;
  }
  return StoryTone.leaf;
}

DateTime? _time(Object? raw) {
  if (raw is! String || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

String encodePromotions(List<Story> stories) {
  return jsonEncode([for (final story in stories) story.toJson()]);
}

List<Story> decodePromotions(String raw) {
  if (raw.trim().isEmpty) return const [];
  try {
    final data = jsonDecode(raw);
    if (data is! List) return const [];
    return [for (final item in data) ?Story.fromJson(item)];
  } catch (_) {
    return const [];
  }
}

List<Story> activeStories(
  StoryPlacement placement,
  DateTime now, {
  required List<Story> source,
}) {
  final rows = [
    for (final story in source)
      if (story.placement == placement && story.isActiveAt(now)) story,
  ]..sort((a, b) => a.sort.compareTo(b.sort));
  return rows;
}
