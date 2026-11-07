import 'models.dart';

class OnlinePayment {
  const OnlinePayment({
    required this.order,
    required this.amountRupees,
    this.keyId = '',
    this.razorpayOrderId = '',
  });

  final OrderRecord order;
  final int amountRupees;
  final String keyId;
  final String razorpayOrderId;

  bool get opensGateway =>
      keyId.startsWith('rzp_') && razorpayOrderId.startsWith('order_');
}
