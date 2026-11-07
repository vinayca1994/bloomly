import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'razorpay_result.dart';

Future<RazorpayCheckoutResult?> openRazorpayCheckout({
  required String keyId,
  required String orderId,
  required int amountPaise,
  required String name,
  required String email,
  required String contact,
  required String description,
}) async {
  final razorpay = Razorpay();
  final completer = Completer<RazorpayCheckoutResult?>();
  void finish(RazorpayCheckoutResult? result) {
    if (completer.isCompleted) return;
    completer.complete(result);
    razorpay.clear();
  }

  razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
    final paidOrder = response.orderId ?? '';
    final paymentId = response.paymentId ?? '';
    final signature = response.signature ?? '';
    if (paidOrder.isEmpty || paymentId.isEmpty || signature.isEmpty) {
      finish(null);
      return;
    }
    finish(
      RazorpayCheckoutResult(
        orderId: paidOrder,
        paymentId: paymentId,
        signature: signature,
      ),
    );
  });
  razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
    finish(null);
  });
  razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
    finish(null);
  });
  razorpay.open({
    'key': keyId,
    'amount': amountPaise,
    'currency': 'INR',
    'name': 'Bloom',
    'description': description,
    'order_id': orderId,
    'prefill': {'name': name, 'email': email, 'contact': contact},
    'method': {
      'upi': true,
      'card': false,
      'netbanking': false,
      'wallet': false,
    },
    'theme': {'color': '#D22B89'},
  });
  return completer.future;
}
