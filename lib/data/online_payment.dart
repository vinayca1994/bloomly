import '../core/upi.dart';
import 'models.dart';

class OnlinePayment {
  const OnlinePayment({
    required this.order,
    required this.upiId,
    required this.upiName,
    required this.amountRupees,
  });

  final OrderRecord order;
  final String upiId;
  final String upiName;
  final int amountRupees;

  String? get payUri => upiPayUri(
    vpa: upiId,
    name: upiName,
    amountRupees: amountRupees,
    note: 'Bloomly ${order.id}',
  );
}
