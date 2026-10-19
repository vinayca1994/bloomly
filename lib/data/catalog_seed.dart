import 'models.dart';

const seedStore = StoreSettings.fallback;

const freshTodayIds = [
  'tomato',
  'spinach',
  'banana',
  'coriander',
  'lemon',
  'cucumber',
];

const regionalFlowerIds = [
  'marigold',
  'jasmine',
  'rose',
  'shiuli',
  'lotus',
  'mogra',
];

const bestsellerIds = [
  'onion',
  'potato',
  'mango',
  'apple',
  'marigold',
  'banana',
];

const seedCategories = <ShopCategory>[
  ShopCategory(
    id: 'vegetables',
    name: 'Vegetables',
    slug: 'vegetables',
    kind: 'vegetable',
    sort: 1,
    emoji: '🥬',
  ),
  ShopCategory(
    id: 'fruits',
    name: 'Fruits',
    slug: 'fruits',
    kind: 'fruit',
    sort: 2,
    emoji: '🍎',
  ),
  ShopCategory(
    id: 'flowers',
    name: 'Flowers',
    slug: 'flowers',
    kind: 'flower',
    sort: 3,
    emoji: '🌸',
  ),
  ShopCategory(
    id: 'daily-veg',
    name: 'Daily',
    slug: 'daily-veg',
    kind: 'vegetable',
    parentSlug: 'vegetables',
    sort: 1,
    emoji: '🍅',
  ),
  ShopCategory(
    id: 'leafy',
    name: 'Leafy',
    slug: 'leafy',
    kind: 'vegetable',
    parentSlug: 'vegetables',
    sort: 2,
    emoji: '🌿',
  ),
  ShopCategory(
    id: 'gourds',
    name: 'Gourds',
    slug: 'gourds',
    kind: 'vegetable',
    parentSlug: 'vegetables',
    sort: 3,
    emoji: '🥒',
  ),
  ShopCategory(
    id: 'roots',
    name: 'Roots',
    slug: 'roots',
    kind: 'vegetable',
    parentSlug: 'vegetables',
    sort: 4,
    emoji: '🥕',
  ),
  ShopCategory(
    id: 'everyday-fruit',
    name: 'Everyday',
    slug: 'everyday-fruit',
    kind: 'fruit',
    parentSlug: 'fruits',
    sort: 1,
    emoji: '🍌',
  ),
  ShopCategory(
    id: 'seasonal-fruit',
    name: 'Seasonal',
    slug: 'seasonal-fruit',
    kind: 'fruit',
    parentSlug: 'fruits',
    sort: 2,
    emoji: '🥭',
  ),
  ShopCategory(
    id: 'citrus',
    name: 'Citrus',
    slug: 'citrus',
    kind: 'fruit',
    parentSlug: 'fruits',
    sort: 3,
    emoji: '🍊',
  ),
  ShopCategory(
    id: 'loose-flowers',
    name: 'Loose',
    slug: 'loose-flowers',
    kind: 'flower',
    parentSlug: 'flowers',
    sort: 1,
    emoji: '🌼',
  ),
  ShopCategory(
    id: 'garlands',
    name: 'Garlands',
    slug: 'garlands',
    kind: 'flower',
    parentSlug: 'flowers',
    sort: 2,
    emoji: '🌺',
  ),
  ShopCategory(
    id: 'bunches',
    name: 'Bunches',
    slug: 'bunches',
    kind: 'flower',
    parentSlug: 'flowers',
    sort: 3,
    emoji: '💐',
  ),
];

Product _p({
  required String id,
  required String name,
  required String categorySlug,
  required String description,
  required int sort,
  required List<List<Object>> options,
  String? imageUrl,
  String region = '',
}) {
  return Product(
    id: id,
    name: name,
    categorySlug: categorySlug,
    description: description,
    imageUrl: imageUrl ?? 'assets/products/$id.jpg',
    isAvailable: true,
    region: region,
    sort: sort,
    variants: [
      for (final option in options)
        Variant(
          id: '$id-${(option[0] as String).toLowerCase().replaceAll(' ', '')}',
          productId: id,
          label: option[0] as String,
          price: option[1] as int,
          mrp: option[2] as int,
          isAvailable: true,
        ),
    ],
  );
}

final seedProducts = <Product>[
  _p(
    id: 'tomato',
    name: 'Tomato',
    categorySlug: 'daily-veg',
    description: 'Firm hybrid tomatoes for salads, rasam, and everyday cooking.',
    sort: 1,
    options: [
      ['250 g', 18, 24],
      ['500 g', 32, 42],
      ['1 kg', 54, 70],
    ],
  ),
  _p(
    id: 'onion',
    name: 'Onion',
    categorySlug: 'daily-veg',
    description: 'Pink onions, dry and sharp, sorted this morning.',
    sort: 2,
    options: [
      ['500 g', 22, 30],
      ['1 kg', 40, 55],
    ],
  ),
  _p(
    id: 'potato',
    name: 'Potato',
    categorySlug: 'daily-veg',
    description: 'Clean table potatoes for curries, fries, and parathas.',
    sort: 3,
    options: [
      ['500 g', 20, 28],
      ['1 kg', 36, 48],
    ],
  ),
  _p(
    id: 'chilli',
    name: 'Green chilli',
    categorySlug: 'daily-veg',
    description: 'Slender green chillies with a clean heat.',
    sort: 4,
    options: [
      ['100 g', 12, 16],
    ],
  ),
  _p(
    id: 'lemon',
    name: 'Lemon',
    categorySlug: 'daily-veg',
    description: 'Juicy lemons, bright enough for nimbu pani.',
    sort: 5,
    options: [
      ['4 pcs', 20, 28],
    ],
  ),
  _p(
    id: 'capsicum',
    name: 'Capsicum',
    categorySlug: 'daily-veg',
    description: 'Crisp green capsicum, mild and glossy.',
    sort: 6,
    options: [
      ['250 g', 28, 36],
    ],
  ),
  _p(
    id: 'cauliflower',
    name: 'Cauliflower',
    categorySlug: 'daily-veg',
    description: 'A tight white head, leaves trimmed.',
    sort: 7,
    options: [
      ['1 pc', 36, 48],
    ],
  ),
  _p(
    id: 'spinach',
    name: 'Spinach',
    categorySlug: 'leafy',
    description: 'Tender palak bunches, roots snipped.',
    sort: 8,
    options: [
      ['1 bunch', 15, 22],
    ],
  ),
  _p(
    id: 'coriander',
    name: 'Coriander',
    categorySlug: 'leafy',
    description: 'Fragrant coriander with the roots still on.',
    sort: 9,
    options: [
      ['1 bunch', 10, 14],
    ],
  ),
  _p(
    id: 'cucumber',
    name: 'Cucumber',
    categorySlug: 'gourds',
    description: 'Cool salad cucumbers, unwaxed.',
    sort: 10,
    options: [
      ['500 g', 24, 32],
    ],
  ),
  _p(
    id: 'beans',
    name: 'French beans',
    categorySlug: 'gourds',
    description: 'Slim beans that snap clean.',
    sort: 11,
    options: [
      ['250 g', 22, 30],
    ],
  ),
  _p(
    id: 'brinjal',
    name: 'Brinjal',
    categorySlug: 'gourds',
    description: 'Small purple brinjals for bharta or fry.',
    sort: 12,
    options: [
      ['500 g', 30, 40],
    ],
  ),
  _p(
    id: 'okra',
    name: 'Okra',
    categorySlug: 'gourds',
    description: 'Tender bhindi, tips still green.',
    sort: 13,
    options: [
      ['250 g', 26, 34],
    ],
  ),
  _p(
    id: 'bottle-gourd',
    name: 'Bottle gourd',
    categorySlug: 'gourds',
    description: 'A young lauki, light in the hand.',
    sort: 14,
    options: [
      ['1 pc', 32, 45],
    ],
  ),
  _p(
    id: 'carrot',
    name: 'Carrot',
    categorySlug: 'roots',
    description: 'Sweet orange carrots, washed.',
    sort: 15,
    options: [
      ['500 g', 28, 38],
    ],
  ),
  _p(
    id: 'ginger',
    name: 'Ginger',
    categorySlug: 'roots',
    description: 'Young ginger with thin skin.',
    sort: 16,
    options: [
      ['100 g', 14, 20],
    ],
  ),
  _p(
    id: 'banana',
    name: 'Banana',
    categorySlug: 'everyday-fruit',
    description: 'Yellaki-style bananas, ripe but firm.',
    sort: 17,
    options: [
      ['6 pcs', 32, 42],
    ],
  ),
  _p(
    id: 'apple',
    name: 'Apple',
    categorySlug: 'everyday-fruit',
    description: 'Crisp red apples, chilled.',
    sort: 18,
    options: [
      ['4 pcs', 120, 160],
    ],
  ),
  _p(
    id: 'papaya',
    name: 'Papaya',
    categorySlug: 'everyday-fruit',
    description: 'A ripening papaya, ready in a day.',
    sort: 19,
    options: [
      ['1 pc', 45, 60],
    ],
  ),
  _p(
    id: 'guava',
    name: 'Guava',
    categorySlug: 'everyday-fruit',
    description: 'White guavas, fragrant and firm.',
    sort: 20,
    options: [
      ['500 g', 40, 55],
    ],
  ),
  _p(
    id: 'sapota',
    name: 'Sapota',
    categorySlug: 'everyday-fruit',
    description: 'Chikoo with a soft give, sweet through.',
    sort: 21,
    options: [
      ['500 g', 48, 64],
    ],
  ),
  _p(
    id: 'mango',
    name: 'Mango',
    categorySlug: 'seasonal-fruit',
    description: 'Seasonal mangoes, ripe and scented.',
    sort: 22,
    options: [
      ['1 kg', 90, 130],
    ],
  ),
  _p(
    id: 'watermelon',
    name: 'Watermelon',
    categorySlug: 'seasonal-fruit',
    description: 'A whole melon, heavy and cool.',
    sort: 23,
    options: [
      ['1 pc', 60, 80],
    ],
  ),
  _p(
    id: 'grapes',
    name: 'Grapes',
    categorySlug: 'seasonal-fruit',
    description: 'Green grapes, bunches still on the stem.',
    sort: 24,
    options: [
      ['500 g', 70, 95],
    ],
  ),
  _p(
    id: 'pomegranate',
    name: 'Pomegranate',
    categorySlug: 'seasonal-fruit',
    description: 'Deep red anar with tight arils.',
    sort: 25,
    options: [
      ['2 pcs', 80, 110],
    ],
  ),
  _p(
    id: 'orange',
    name: 'Orange',
    categorySlug: 'citrus',
    description: 'Nagpur-style oranges, easy to peel.',
    sort: 26,
    options: [
      ['4 pcs', 50, 70],
    ],
  ),
  _p(
    id: 'marigold',
    name: 'Marigold',
    categorySlug: 'loose-flowers',
    description: 'Genda blooms from the north, dense and golden.',
    sort: 27,
    region: 'North',
    options: [
      ['1 bunch', 30, 40],
    ],
  ),
  _p(
    id: 'jasmine',
    name: 'Jasmine',
    categorySlug: 'loose-flowers',
    description: 'Malli stringed the south Indian way.',
    sort: 28,
    region: 'South',
    options: [
      ['1 string', 40, 55],
    ],
  ),
  _p(
    id: 'hibiscus',
    name: 'Hibiscus',
    categorySlug: 'loose-flowers',
    description: 'Chembarathi stems, open and red.',
    sort: 29,
    region: 'South',
    options: [
      ['5 stems', 35, 48],
    ],
  ),
  _p(
    id: 'shiuli',
    name: 'Shiuli',
    categorySlug: 'loose-flowers',
    description: 'Night-blooming shiuli, a small eastern bowl.',
    sort: 30,
    region: 'East',
    options: [
      ['1 bowl', 45, 60],
    ],
  ),
  _p(
    id: 'rose',
    name: 'Rose',
    categorySlug: 'loose-flowers',
    description: 'Red roses grown for the western markets.',
    sort: 31,
    region: 'West',
    options: [
      ['5 stems', 50, 70],
    ],
  ),
  _p(
    id: 'mogra',
    name: 'Mogra',
    categorySlug: 'loose-flowers',
    description: 'A mogra string, sweet even through the wrap.',
    sort: 32,
    region: 'West',
    options: [
      ['1 string', 45, 60],
    ],
  ),
  _p(
    id: 'lotus',
    name: 'Lotus',
    categorySlug: 'loose-flowers',
    description: 'A single lotus stem for the puja thali.',
    sort: 33,
    region: 'East',
    options: [
      ['1 stem', 40, 55],
    ],
  ),
  _p(
    id: 'tuberose',
    name: 'Tuberose',
    categorySlug: 'bunches',
    description: 'Rajnigandha bunches from the northern fields.',
    sort: 34,
    region: 'North',
    options: [
      ['1 bunch', 60, 80],
    ],
  ),
  _p(
    id: 'chrysanthemum',
    name: 'Chrysanthemum',
    categorySlug: 'bunches',
    description: 'Soft chrysanthemum heads in a market bunch.',
    sort: 35,
    region: 'North',
    options: [
      ['1 bunch', 55, 75],
    ],
  ),
  _p(
    id: 'tuberose-garland',
    name: 'Tuberose garland',
    categorySlug: 'garlands',
    description: 'A long rajnigandha garland strung in the east.',
    sort: 36,
    region: 'East',
    options: [
      ['1 string', 120, 160],
    ],
  ),
];

ShopCategory? categoryBySlug(List<ShopCategory> categories, String slug) {
  for (final category in categories) {
    if (category.slug == slug) return category;
  }
  return null;
}

String emojiFor(Product product, List<ShopCategory> categories) {
  return categoryBySlug(categories, product.categorySlug)?.emoji ??
      categoryBySlug(categories, _kindSlug(product, categories))?.emoji ??
      '🛒';
}

String _kindSlug(Product product, List<ShopCategory> categories) {
  final category = categoryBySlug(categories, product.categorySlug);
  if (category == null) return '';
  if (category.kind == 'vegetable') return 'vegetables';
  if (category.kind == 'fruit') return 'fruits';
  return 'flowers';
}

ColorKind kindFor(Product product, List<ShopCategory> categories) {
  final category = categoryBySlug(categories, product.categorySlug);
  switch (category?.kind) {
    case 'fruit':
      return ColorKind.fruit;
    case 'flower':
      return ColorKind.flower;
    default:
      return ColorKind.vegetable;
  }
}

enum ColorKind { vegetable, fruit, flower }
