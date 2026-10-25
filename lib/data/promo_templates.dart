import 'package:flutter/material.dart';

import '../core/bloom_tokens.dart';
import 'stories.dart';

enum PromoComposition { poster, stack, ticket }

class PromoStyle {
  const PromoStyle({
    required this.id,
    required this.name,
    required this.composition,
    required this.motif,
  });

  final String id;
  final String name;
  final PromoComposition composition;
  final StoryMotif motif;
}

class PromoLook {
  const PromoLook({
    required this.ground,
    required this.ink,
    required this.accent,
    required this.motif,
  });

  final Color ground;
  final Color ink;
  final Color accent;
  final StoryMotif motif;
}

class PromoTemplate {
  const PromoTemplate({
    required this.id,
    required this.category,
    required this.name,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.tone,
    required this.look,
    this.styles = const [],
    this.route,
  });

  final String id;
  final String category;
  final String name;
  final String eyebrow;
  final String title;
  final String subtitle;
  final StoryTone tone;
  final PromoLook look;
  final List<PromoStyle> styles;
  final String? route;

  Story story({required String id, required int sort}) {
    final style = styles.isEmpty ? null : styles.first;
    return Story(
      id: id,
      placement: StoryPlacement.homeBanner,
      title: title,
      subtitle: subtitle,
      tone: tone,
      themeId: this.id,
      styleId: style?.id ?? '',
      eyebrow: eyebrow,
      motif: style?.motif ?? look.motif,
      route: route,
      sort: sort,
    );
  }
}

PromoLook? promoLook(String themeId) {
  for (final template in promoTemplates) {
    if (template.id == themeId) return template.look;
  }
  return null;
}

List<PromoStyle> promoStyles(String themeId) {
  for (final template in promoTemplates) {
    if (template.id == themeId) return template.styles;
  }
  return const [];
}

PromoStyle? promoStyle(String themeId, String styleId) {
  final styles = promoStyles(themeId);
  for (final style in styles) {
    if (style.id == styleId) return style;
  }
  if (styles.isEmpty) return null;
  return styles.first;
}

const promoDestinations = <(String, String)>[
  ('Vegetables', '/categories/vegetables'),
  ('Daily veg', '/categories/vegetables?sub=daily-veg'),
  ('Leafy', '/categories/vegetables?sub=leafy'),
  ('Fruits', '/categories/fruits'),
  ('Seasonal fruit', '/categories/fruits?sub=seasonal-fruit'),
  ('Everyday fruit', '/categories/fruits?sub=everyday-fruit'),
  ('Citrus', '/categories/fruits?sub=citrus'),
  ('Flowers', '/categories/flowers'),
  ('Loose flowers', '/categories/flowers?sub=loose-flowers'),
];

const promoAisles = <(String, String)>[
  ('Vegetables', '/categories/vegetables'),
  ('Fruits', '/categories/fruits'),
  ('Flowers', '/categories/flowers'),
];

const promoTemplates = <PromoTemplate>[
  PromoTemplate(
    id: 'ugadi',
    category: 'Festival',
    name: 'Ugadi',
    eyebrow: 'Ugadi',
    title: 'Neem, jaggery, and flowers',
    subtitle: 'The new-year mixture',
    tone: StoryTone.leaf,
    route: '/categories/vegetables?sub=leafy',
    look: PromoLook(
      ground: Basil.s900,
      ink: Sun.s50,
      accent: Mango.s300,
      motif: StoryMotif.neem,
    ),
    styles: [
      PromoStyle(
        id: 'ugadi-poster',
        name: 'Neem poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.neem,
      ),
      PromoStyle(
        id: 'ugadi-stack',
        name: 'Jaggery stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.cane,
      ),
      PromoStyle(
        id: 'ugadi-ticket',
        name: 'Flower ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.flower,
      ),
    ],
  ),
  PromoTemplate(
    id: 'sankranti',
    category: 'Festival',
    name: 'Sankranti',
    eyebrow: 'Sankranti',
    title: 'Sugarcane, sesame, and ripe fruit',
    subtitle: 'The harvest plate',
    tone: StoryTone.fruit,
    route: '/categories/fruits?sub=seasonal-fruit',
    look: PromoLook(
      ground: Sun.s200,
      ink: Plum.s900,
      accent: Sky.s700,
      motif: StoryMotif.cane,
    ),
    styles: [
      PromoStyle(
        id: 'sankranti-poster',
        name: 'Cane poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.cane,
      ),
      PromoStyle(
        id: 'sankranti-stack',
        name: 'Sun stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.orange,
      ),
      PromoStyle(
        id: 'sankranti-ticket',
        name: 'Harvest ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.cane,
      ),
    ],
  ),
  PromoTemplate(
    id: 'ganesh',
    category: 'Festival',
    name: 'Ganesh',
    eyebrow: 'Ganesh',
    title: 'Flowers by the stem',
    subtitle: 'Loose flowers for the day',
    tone: StoryTone.flower,
    route: '/categories/flowers?sub=loose-flowers',
    look: PromoLook(
      ground: Petal.s100,
      ink: Petal.s900,
      accent: Mango.s600,
      motif: StoryMotif.flower,
    ),
    styles: [
      PromoStyle(
        id: 'ganesh-poster',
        name: 'Stem poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.flower,
      ),
      PromoStyle(
        id: 'ganesh-stack',
        name: 'Leaf stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.leaf,
      ),
      PromoStyle(
        id: 'ganesh-ticket',
        name: 'Garland ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.flower,
      ),
    ],
  ),
  PromoTemplate(
    id: 'diwali',
    category: 'Festival',
    name: 'Diwali',
    eyebrow: 'Diwali',
    title: 'Marigolds for the house',
    subtitle: 'Lamps and loose flowers',
    tone: StoryTone.marigold,
    route: '/categories/flowers?sub=loose-flowers',
    look: PromoLook(
      ground: Plum.s950,
      ink: Sun.s100,
      accent: Sun.s300,
      motif: StoryMotif.lamp,
    ),
    styles: [
      PromoStyle(
        id: 'diwali-poster',
        name: 'Lamp poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.lamp,
      ),
      PromoStyle(
        id: 'diwali-stack',
        name: 'Marigold stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.flower,
      ),
      PromoStyle(
        id: 'diwali-ticket',
        name: 'Gold ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.lamp,
      ),
    ],
  ),
  PromoTemplate(
    id: 'onam',
    category: 'Festival',
    name: 'Onam',
    eyebrow: 'Onam',
    title: 'The sadya basket',
    subtitle: 'A banana leaf of the feast',
    tone: StoryTone.leaf,
    route: '/categories/vegetables',
    look: PromoLook(
      ground: Basil.s700,
      ink: bloomWhite,
      accent: Sun.s200,
      motif: StoryMotif.leaf,
    ),
    styles: [
      PromoStyle(
        id: 'onam-poster',
        name: 'Leaf poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.leaf,
      ),
      PromoStyle(
        id: 'onam-stack',
        name: 'Feast stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.basket,
      ),
      PromoStyle(
        id: 'onam-ticket',
        name: 'Sadya ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.leaf,
      ),
    ],
  ),
  PromoTemplate(
    id: 'christmas',
    category: 'Festival',
    name: 'Christmas',
    eyebrow: 'Christmas',
    title: 'A box of ripe fruit',
    subtitle: 'Pine green and the fruit bowl',
    tone: StoryTone.fruit,
    route: '/categories/fruits?sub=everyday-fruit',
    look: PromoLook(
      ground: Chili.s800,
      ink: Petal.s50,
      accent: Basil.s300,
      motif: StoryMotif.orange,
    ),
    styles: [
      PromoStyle(
        id: 'christmas-poster',
        name: 'Fruit poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.orange,
      ),
      PromoStyle(
        id: 'christmas-stack',
        name: 'Pine stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.leaf,
      ),
      PromoStyle(
        id: 'christmas-ticket',
        name: 'Box ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.basket,
      ),
    ],
  ),
  PromoTemplate(
    id: 'summer-fruit',
    category: 'Season',
    name: 'Summer',
    eyebrow: 'Summer',
    title: 'Mangoes and the hot-season basket',
    subtitle: 'The fruit that marks the heat',
    tone: StoryTone.fruit,
    route: '/categories/fruits?sub=seasonal-fruit',
    look: PromoLook(
      ground: Mango.s300,
      ink: Plum.s900,
      accent: Chili.s700,
      motif: StoryMotif.mango,
    ),
    styles: [
      PromoStyle(
        id: 'summer-poster',
        name: 'Mango poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.mango,
      ),
      PromoStyle(
        id: 'summer-stack',
        name: 'Heat stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.mango,
      ),
      PromoStyle(
        id: 'summer-ticket',
        name: 'Basket ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.basket,
      ),
    ],
  ),
  PromoTemplate(
    id: 'monsoon-leafy',
    category: 'Season',
    name: 'Monsoon',
    eyebrow: 'Monsoon',
    title: 'Greens for the rainy week',
    subtitle: 'Bunches after the rain',
    tone: StoryTone.leaf,
    route: '/categories/vegetables?sub=leafy',
    look: PromoLook(
      ground: Sky.s900,
      ink: Sky.s50,
      accent: Basil.s300,
      motif: StoryMotif.rain,
    ),
    styles: [
      PromoStyle(
        id: 'monsoon-poster',
        name: 'Rain poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.rain,
      ),
      PromoStyle(
        id: 'monsoon-stack',
        name: 'Leaf stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.leaf,
      ),
      PromoStyle(
        id: 'monsoon-ticket',
        name: 'Week ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.rain,
      ),
    ],
  ),
  PromoTemplate(
    id: 'winter-citrus',
    category: 'Season',
    name: 'Winter',
    eyebrow: 'Winter',
    title: 'Oranges and lemons',
    subtitle: 'The citrus bowl',
    tone: StoryTone.fruit,
    route: '/categories/fruits?sub=citrus',
    look: PromoLook(
      ground: Mango.s50,
      ink: Plum.s900,
      accent: Mango.s600,
      motif: StoryMotif.orange,
    ),
    styles: [
      PromoStyle(
        id: 'winter-poster',
        name: 'Citrus poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.orange,
      ),
      PromoStyle(
        id: 'winter-stack',
        name: 'Bowl stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.orange,
      ),
      PromoStyle(
        id: 'winter-ticket',
        name: 'Lemon ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.leaf,
      ),
    ],
  ),
  PromoTemplate(
    id: 'free-delivery',
    category: 'Offer',
    name: 'Free delivery',
    eyebrow: 'Offer',
    title: 'Free delivery',
    subtitle: 'Bigger baskets skip the fee',
    tone: StoryTone.leaf,
    route: '/categories/vegetables',
    look: PromoLook(
      ground: Basil.s50,
      ink: Basil.s900,
      accent: Petal.s600,
      motif: StoryMotif.leaf,
    ),
    styles: [
      PromoStyle(
        id: 'delivery-poster',
        name: 'Leaf poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.leaf,
      ),
      PromoStyle(
        id: 'delivery-stack',
        name: 'Offer stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.leaf,
      ),
      PromoStyle(
        id: 'delivery-ticket',
        name: 'Skip ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.basket,
      ),
    ],
  ),
  PromoTemplate(
    id: 'opening-week',
    category: 'Offer',
    name: 'Opening week',
    eyebrow: 'New',
    title: 'Just opened',
    subtitle: 'Vegetables, fruit, and flowers in minutes',
    tone: StoryTone.marigold,
    route: '/categories/vegetables',
    look: PromoLook(
      ground: Petal.s600,
      ink: bloomWhite,
      accent: Sun.s300,
      motif: StoryMotif.basket,
    ),
    styles: [
      PromoStyle(
        id: 'opening-poster',
        name: 'Opened poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.basket,
      ),
      PromoStyle(
        id: 'opening-stack',
        name: 'Week stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.flower,
      ),
      PromoStyle(
        id: 'opening-ticket',
        name: 'Marigold ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.leaf,
      ),
    ],
  ),
  PromoTemplate(
    id: 'weekend-basket',
    category: 'Offer',
    name: 'Weekend basket',
    eyebrow: 'Weekend',
    title: 'Stock the kitchen for two days',
    subtitle: 'A basket for Saturday and Sunday',
    tone: StoryTone.leaf,
    route: '/categories/vegetables?sub=daily-veg',
    look: PromoLook(
      ground: Basil.s50,
      ink: Plum.s900,
      accent: Basil.s700,
      motif: StoryMotif.basket,
    ),
    styles: [
      PromoStyle(
        id: 'weekend-poster',
        name: 'Basket poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.basket,
      ),
      PromoStyle(
        id: 'weekend-stack',
        name: 'Kitchen stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.leaf,
      ),
      PromoStyle(
        id: 'weekend-ticket',
        name: 'Two-day ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.basket,
      ),
    ],
  ),
  PromoTemplate(
    id: 'flowers-by-region',
    category: 'Shop',
    name: 'Flowers by region',
    eyebrow: 'Flowers',
    title: 'North, South, East, and West',
    subtitle: 'Pick a region',
    tone: StoryTone.flower,
    route: '/categories/flowers',
    look: PromoLook(
      ground: Petal.s50,
      ink: Plum.s900,
      accent: Petal.s700,
      motif: StoryMotif.region,
    ),
    styles: [
      PromoStyle(
        id: 'region-poster',
        name: 'Region poster',
        composition: PromoComposition.poster,
        motif: StoryMotif.region,
      ),
      PromoStyle(
        id: 'region-stack',
        name: 'Compass stack',
        composition: PromoComposition.stack,
        motif: StoryMotif.flower,
      ),
      PromoStyle(
        id: 'region-ticket',
        name: 'Map ticket',
        composition: PromoComposition.ticket,
        motif: StoryMotif.region,
      ),
    ],
  ),
];

const promoCategories = ['Festival', 'Season', 'Offer', 'Shop'];
