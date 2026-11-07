import 'service_area.dart';
import 'stories.dart';

class StoreSettings {
  const StoreSettings({
    required this.city,
    required this.etaLabel,
    required this.deliveryFee,
    required this.freeDeliveryAbove,
    this.pincode = launchPincode,
    this.upiId = '',
    this.upiName = 'Bloom',
    this.storePhone = '',
    this.promotions = const [],
  });

  final String city;
  final String etaLabel;
  final int deliveryFee;
  final int freeDeliveryAbove;

  /// Indian pin the store delivers to. Empty falls back to [launchPincode].
  final String pincode;
  final String upiId;
  final String upiName;

  /// Indian mobile for call / WhatsApp (10 digits or +91…).
  final String storePhone;

  /// Banners the owner has saved. Hidden and out-of-date rows stay here.
  final List<Story> promotions;

  static const fallback = StoreSettings(
    city: launchCity,
    etaLabel: '15–30 min',
    deliveryFee: 25,
    freeDeliveryAbove: 199,
  );

  StoreSettings copyWith({
    String? city,
    String? etaLabel,
    int? deliveryFee,
    int? freeDeliveryAbove,
    String? pincode,
    String? upiId,
    String? upiName,
    String? storePhone,
    List<Story>? promotions,
  }) {
    return StoreSettings(
      city: city ?? this.city,
      etaLabel: etaLabel ?? this.etaLabel,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
      pincode: pincode ?? this.pincode,
      upiId: upiId ?? this.upiId,
      upiName: upiName ?? this.upiName,
      storePhone: storePhone ?? this.storePhone,
      promotions: promotions ?? this.promotions,
    );
  }

  Map<String, dynamic> toMap() => {
    'city': city,
    'etaLabel': etaLabel,
    'deliveryFee': deliveryFee,
    'freeDeliveryAbove': freeDeliveryAbove,
    'pincode': pincode,
    'upiId': upiId,
    'upiName': upiName,
    'storePhone': storePhone,
    'promotions': encodePromotions(promotions),
  };
}

class ShopCategory {
  const ShopCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.kind,
    required this.sort,
    required this.emoji,
    this.parentSlug,
  });

  final String id;
  final String name;
  final String slug;

  /// vegetable, fruit, or flower.
  final String kind;
  final String? parentSlug;
  final int sort;
  final String emoji;

  bool get isGroup => parentSlug == null;
}

class Variant {
  const Variant({
    required this.id,
    required this.productId,
    required this.label,
    required this.price,
    required this.mrp,
    required this.isAvailable,
  });

  final String id;
  final String productId;
  final String label;
  final int price;
  final int mrp;
  final bool isAvailable;

  Variant copyWith({int? price, int? mrp, bool? isAvailable, String? label}) {
    return Variant(
      id: id,
      productId: productId,
      label: label ?? this.label,
      price: price ?? this.price,
      mrp: mrp ?? this.mrp,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'label': label,
    'price': price,
    'mrp': mrp,
    'isAvailable': isAvailable,
  };
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.categorySlug,
    required this.description,
    required this.isAvailable,
    required this.sort,
    required this.variants,
    this.imageUrl,
    this.region = '',
  });

  final String id;
  final String name;
  final String categorySlug;
  final String description;
  final String? imageUrl;
  final bool isAvailable;
  final String region;
  final int sort;
  final List<Variant> variants;

  bool get forSale =>
      isAvailable && variants.any((variant) => variant.isAvailable);

  Variant get lead {
    final available = variants.where((variant) => variant.isAvailable).toList();
    final pool = available.isEmpty ? variants : available;
    final sorted = [...pool]..sort((a, b) => a.price.compareTo(b.price));
    return sorted.first;
  }

  Product copyWith({
    String? name,
    String? categorySlug,
    String? description,
    String? imageUrl,
    bool? isAvailable,
    String? region,
    int? sort,
    List<Variant>? variants,
    bool clearImage = false,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      categorySlug: categorySlug ?? this.categorySlug,
      description: description ?? this.description,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      isAvailable: isAvailable ?? this.isAvailable,
      region: region ?? this.region,
      sort: sort ?? this.sort,
      variants: variants ?? this.variants,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'categorySlug': categorySlug,
    'description': description,
    'imageUrl': imageUrl ?? '',
    'isAvailable': isAvailable,
    'region': region,
    'sort': sort,
  };
}

class PaymentMethod {
  static const cod = 'cod';
  static const upi = 'upi';
}

class PaymentStatus {
  static const pending = 'pending';
  static const submitted = 'submitted';
  static const paid = 'paid';
  static const failed = 'failed';
  static const refundPending = 'refund_pending';
  static const refunded = 'refunded';
}

class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;

  bool get isOwner => role == 'owner';

  bool get isRider => role == 'rider';

  String get contact => email.isNotEmpty ? email : phone;
}

class Address {
  const Address({
    required this.id,
    required this.userId,
    required this.label,
    required this.line,
    required this.area,
    required this.city,
    required this.pincode,
    required this.isDefault,
    this.landmark = '',
    this.latitude,
    this.longitude,
  });

  final String id;
  final String userId;
  final String label;
  final String line;
  final String area;
  final String city;
  final String pincode;
  final String landmark;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  String get snapshot {
    final place = landmark.trim().isEmpty ? line : '$line, ${landmark.trim()}';
    return '$label · $place, $area, $city $pincode';
  }

  Address copyWith({
    String? label,
    String? line,
    String? area,
    String? city,
    String? pincode,
    String? landmark,
    bool? isDefault,
    double? latitude,
    double? longitude,
    bool clearCoords = false,
  }) {
    return Address(
      id: id,
      userId: userId,
      label: label ?? this.label,
      line: line ?? this.line,
      area: area ?? this.area,
      city: city ?? this.city,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      isDefault: isDefault ?? this.isDefault,
      latitude: clearCoords ? null : (latitude ?? this.latitude),
      longitude: clearCoords ? null : (longitude ?? this.longitude),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'label': label,
    'line': line,
    'area': area,
    'city': city,
    'pincode': pincode,
    'landmark': landmark,
    'isDefault': isDefault,
    'latitude': latitude?.toString() ?? '',
    'longitude': longitude?.toString() ?? '',
  };
}

class OrderStatus {
  static const placed = 'placed';
  static const packing = 'packing';
  static const outForDelivery = 'out_for_delivery';
  static const delivered = 'delivered';
  static const cancelled = 'cancelled';
  static const paymentPending = 'payment_pending';

  static const flow = [placed, packing, outForDelivery, delivered];

  static bool visibleToStore(String status) => status != paymentPending;

  static String? next(String status) {
    switch (status) {
      case placed:
        return packing;
      case packing:
        return outForDelivery;
      case outForDelivery:
        return delivered;
      default:
        return null;
    }
  }

  static bool canCancel(String status) {
    return status == placed ||
        status == packing ||
        status == outForDelivery ||
        status == paymentPending;
  }

  /// Customer may cancel only before packing starts (and while UPI is unpaid).
  static bool customerCanCancel(String status) {
    return status == placed || status == paymentPending;
  }

  /// Owner sends a packed order out, or changes the rider while it is out.
  static bool canAssign(String status) {
    return status == packing || status == outForDelivery;
  }
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.name,
    required this.variantLabel,
    required this.unitPrice,
    required this.qty,
  });

  final String id;
  final String orderId;
  final String productId;
  final String name;
  final String variantLabel;
  final int unitPrice;
  final int qty;

  int get lineTotal => unitPrice * qty;

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'productId': productId,
    'name': name,
    'variantLabel': variantLabel,
    'unitPrice': unitPrice,
    'qty': qty,
  };
}

class OrderRecord {
  const OrderRecord({
    required this.id,
    required this.userId,
    required this.addressSnapshot,
    required this.status,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.paymentMethod,
    required this.placedAt,
    required this.items,
    this.paymentStatus = PaymentStatus.pending,
    this.gatewayOrderId = '',
    this.gatewayPaymentId = '',
    this.upiTxnRef = '',
    this.riderId = '',
    this.riderName = '',
    this.customerPhone = '',
    this.destLatitude,
    this.destLongitude,
  });

  final String id;
  final String userId;
  final String addressSnapshot;
  final String status;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final String paymentMethod;
  final String paymentStatus;
  final String gatewayOrderId;
  final String gatewayPaymentId;
  final String upiTxnRef;
  final String riderId;
  final String riderName;
  final String customerPhone;
  final double? destLatitude;
  final double? destLongitude;
  final DateTime placedAt;
  final List<OrderItem> items;

  bool get awaitingPayment => status == OrderStatus.paymentPending;

  static const upiPaymentTimeout = Duration(minutes: 45);

  bool get upiTimedOut =>
      awaitingPayment &&
      paymentMethod == PaymentMethod.upi &&
      DateTime.now().difference(placedAt) >= upiPaymentTimeout;

  /// Collected money for today: UPI marked paid, or cash marked paid on delivery.
  bool countsAsRevenue(DateTime now) {
    final placed = placedAt.toLocal();
    final day = now.toLocal();
    if (placed.year != day.year ||
        placed.month != day.month ||
        placed.day != day.day) {
      return false;
    }
    if (status == OrderStatus.cancelled || status == OrderStatus.paymentPending) {
      return false;
    }
    if (paymentStatus != PaymentStatus.paid) return false;
    return true;
  }

  OrderRecord copyWith({
    String? status,
    List<OrderItem>? items,
    String? paymentStatus,
    String? gatewayOrderId,
    String? gatewayPaymentId,
    String? upiTxnRef,
    String? riderId,
    String? riderName,
    double? destLatitude,
    double? destLongitude,
  }) {
    return OrderRecord(
      id: id,
      userId: userId,
      addressSnapshot: addressSnapshot,
      status: status ?? this.status,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      paymentMethod: paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      gatewayOrderId: gatewayOrderId ?? this.gatewayOrderId,
      gatewayPaymentId: gatewayPaymentId ?? this.gatewayPaymentId,
      upiTxnRef: upiTxnRef ?? this.upiTxnRef,
      riderId: riderId ?? this.riderId,
      riderName: riderName ?? this.riderName,
      customerPhone: customerPhone,
      destLatitude: destLatitude ?? this.destLatitude,
      destLongitude: destLongitude ?? this.destLongitude,
      placedAt: placedAt,
      items: items ?? this.items,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'addressSnapshot': addressSnapshot,
    'status': status,
    'subtotal': subtotal,
    'deliveryFee': deliveryFee,
    'total': total,
    'paymentMethod': paymentMethod,
    'paymentStatus': paymentStatus,
    'gatewayOrderId': gatewayOrderId,
    'gatewayPaymentId': gatewayPaymentId,
    'upiTxnRef': upiTxnRef,
    'riderId': riderId,
    'riderName': riderName,
    'customerPhone': customerPhone,
    'destLatitude': destLatitude?.toString() ?? '',
    'destLongitude': destLongitude?.toString() ?? '',
    'placedAt': placedAt.toIso8601String(),
  };
}

/// Latest pin for one delivery. The rider updates this row only.
class RiderLocation {
  const RiderLocation({
    required this.orderId,
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  final String orderId;
  final double latitude;
  final double longitude;
  final DateTime updatedAt;
}

/// One review for a delivered order. Scores are 1 to 5 and stay as sent.
class DeliveryReview {
  const DeliveryReview({
    required this.orderId,
    required this.userId,
    required this.riderId,
    required this.freshness,
    required this.rightItems,
    required this.packing,
    required this.onTime,
    required this.polite,
    required this.careful,
    required this.createdAt,
    this.note = '',
  });

  static const minScore = 1;
  static const maxScore = 5;

  final String orderId;
  final String userId;
  final String riderId;
  final int freshness;
  final int rightItems;
  final int packing;
  final int onTime;
  final int polite;
  final int careful;
  final String note;
  final DateTime createdAt;

  static bool validScore(int score) => score >= minScore && score <= maxScore;

  static String? rejectScores({
    required int freshness,
    required int rightItems,
    required int packing,
    required int onTime,
    required int polite,
    required int careful,
    String note = '',
  }) {
    final scores = [freshness, rightItems, packing, onTime, polite, careful];
    if (!scores.every(validScore)) return 'Choose 1 to 5 stars for each part.';
    if (note.trim().length > 280) return 'Keep the note under 280 characters.';
    return null;
  }

  Map<String, dynamic> toMap() => {
    'orderId': orderId,
    'userId': userId,
    'riderId': riderId,
    'freshness': freshness,
    'rightItems': rightItems,
    'packing': packing,
    'onTime': onTime,
    'polite': polite,
    'careful': careful,
    'note': note.trim(),
    'createdAt': createdAt.toIso8601String(),
  };
}

class CartLine {
  const CartLine({
    required this.productId,
    required this.variantId,
    required this.qty,
  });

  final String productId;
  final String variantId;
  final int qty;

  CartLine copyWith({int? qty}) {
    return CartLine(
      productId: productId,
      variantId: variantId,
      qty: qty ?? this.qty,
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'variantId': variantId,
    'qty': qty,
  };

  factory CartLine.fromJson(Map<String, dynamic> json) {
    return CartLine(
      productId: json['productId'] as String,
      variantId: json['variantId'] as String,
      qty: (json['qty'] as num).toInt(),
    );
  }
}

class BloomlyException implements Exception {
  BloomlyException(this.message);
  final String message;

  @override
  String toString() => message;
}
