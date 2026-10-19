import 'package:intl/intl.dart';

import '../data/models.dart';

final _grouping = NumberFormat.decimalPattern('en_IN');

String money(int rupees) => '₹${_grouping.format(rupees)}';

int percentOff(int price, int mrp) {
  if (mrp <= 0 || price >= mrp) return 0;
  return (((mrp - price) * 100) / mrp).round();
}

String formatWhen(DateTime time) {
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
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.hour >= 12 ? 'pm' : 'am';
  return '${time.day} ${months[time.month - 1]}, $hour:$minute $suffix';
}

String statusLabel(String status) {
  switch (status) {
    case OrderStatus.placed:
      return 'Placed';
    case OrderStatus.packing:
      return 'Packing';
    case OrderStatus.outForDelivery:
      return 'Out for delivery';
    case OrderStatus.delivered:
      return 'Delivered';
    case OrderStatus.cancelled:
      return 'Cancelled';
    case OrderStatus.paymentPending:
      return 'Awaiting payment';
    default:
      return status;
  }
}

String paymentLabel(OrderRecord order) {
  if (order.paymentMethod == PaymentMethod.cod) return 'Cash on delivery';
  if (order.paymentStatus == PaymentStatus.paid) return 'Paid by UPI';
  if (order.paymentStatus == PaymentStatus.submitted) return 'UPI sent, waiting for the store';
  if (order.paymentStatus == PaymentStatus.failed) return 'UPI payment failed';
  return 'Pay with UPI';
}

String customerStatusLabel(OrderRecord order) {
  if (order.paymentStatus == PaymentStatus.submitted) return 'UPI sent';
  return statusLabel(order.status);
}

String nextStatusAction(String status) {
  switch (OrderStatus.next(status)) {
    case OrderStatus.packing:
      return 'Start packing';
    case OrderStatus.outForDelivery:
      return 'Out for delivery';
    case OrderStatus.delivered:
      return 'Mark delivered';
    default:
      return '';
  }
}

bool sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
