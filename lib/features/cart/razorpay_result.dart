class RazorpayCheckoutResult {
  const RazorpayCheckoutResult({
    required this.orderId,
    required this.paymentId,
    required this.signature,
  });

  final String orderId;
  final String paymentId;
  final String signature;
}

String razorpayContact(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 10) return digits.substring(digits.length - 10);
  return digits;
}
