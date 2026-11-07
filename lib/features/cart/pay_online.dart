import '../../data/backend.dart';
import '../../data/models.dart';
import '../../data/online_payment.dart';
import 'razorpay_checkout.dart';

/// Opens Razorpay and asks the server to mark the order paid.
///
/// A null result means the payment was captured. A string is the message to show.
Future<String?> payWithRazorpay({
  required BloomlyBackend backend,
  required OnlinePayment payment,
  required Profile? user,
}) async {
  if (!payment.opensGateway) return 'Online payment is not set up yet.';
  final result = await openRazorpayCheckout(
    keyId: payment.keyId,
    orderId: payment.razorpayOrderId,
    amountPaise: payment.amountRupees * 100,
    name: user?.name ?? '',
    email: user?.email ?? '',
    contact: razorpayContact(user?.phone ?? ''),
    description: 'Bloom ${payment.order.id}',
  );
  if (result == null) return 'Payment cancelled.';
  return backend.verifyOnlinePayment(
    orderId: payment.order.id,
    razorpayOrderId: result.orderId,
    razorpayPaymentId: result.paymentId,
    signature: result.signature,
  );
}
