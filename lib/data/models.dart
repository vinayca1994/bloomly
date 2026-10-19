class StoreSettings {
  const StoreSettings({
    required this.city,
    required this.etaLabel,
    required this.deliveryFee,
    required this.freeDeliveryAbove,
    this.upiId = '',
    this.upiName = 'Bloomly',
  });

  final String city;
  final String etaLabel;
  final int deliveryFee;
  final int freeDeliveryAbove;
  final String upiId;
  final String upiName;

  static const fallback = StoreSettings(
    city: 'Bengaluru',
    etaLabel: '15–30 min',
    deliveryFee: 25,
    freeDeliveryAbove: 199,
  );

  StoreSettings copyWith({
    String? city,
    String? etaLabel,
    int? deliveryFee,
    int? freeDeliveryAbove,
    String? upiId,
    String? upiName,
  }) {
    return StoreSettings(
      city: city ?? this.city,
      etaLabel: etaLabel ?? this.etaLabel,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryAbove: freeDeliveryAbove ?? this.freeDeliveryAbove,
      upiId: upiId ?? this.upiId,
      upiName: upiName ?? this.upiName,
    );
  }

  Map<String, dynamic> toMap() => {
    'city': city,
    'etaLabel': etaLabel,
    'deliveryFee': deliveryFee,
    'freeDeliveryAbove': freeDeliveryAbove,
    'upiId': upiId,
    'upiName': upiName,
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
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  String get snapshot => '$label · $line, $area, $city $pincode';

  Address copyWith({bool? isDefault}) {
    return Address(
      id: id,
      userId: userId,
      label: label,
      line: line,
      area: area,
      city: city,
      pincode: pincode,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'label': label,
    'line': line,
    'area': area,
    'city': city,
    'pincode': pincode,
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
        status == outForDelivery;
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
  final DateTime placedAt;
  final List<OrderItem> items;

  bool get awaitingPayment => status == OrderStatus.paymentPending;

  OrderRecord copyWith({
    String? status,
    List<OrderItem>? items,
    String? paymentStatus,
    String? gatewayOrderId,
    String? gatewayPaymentId,
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
    'placedAt': placedAt.toIso8601String(),
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
