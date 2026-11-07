import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Decisions the payments function can make without Appwrite.
const maxCartLines = 40;
const maxLineQty = 99;
const upiHold = Duration(minutes: 45);
const deletePageSize = 100;
const reauthWindow = Duration(minutes: 5);
const launchPincode = '563130';

final idempotencyKeyPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$');
final upiReferencePattern = RegExp(r'^[A-Za-z0-9]{1,35}$');

const cartTooBig = 'Too many items in the cart.';
const cartQty = 'Check the quantities in your cart.';
const cartEmpty = 'Add an address and at least one item.';
const confirmWait = 'Wait for the customer’s UPI reference before confirming.';
const confirmNotWaiting = 'This order is not awaiting a UPI payment.';
const confirmNotUpi = 'This order was not paid by UPI.';
const confirmOwner = 'Only the store can confirm a UPI payment.';
const confirmClosed =
    'The store does not confirm a UPI reference. Razorpay confirms the payment.';
const paymentStarting = 'Payment is already starting. Try again.';
const refundFailed = 'The refund could not be sent. Try again.';
const accountHasPaidOrders =
    'Refund the paid UPI orders before deleting the account.';
const gatewayClaimPrefix = 'claim:';
const gatewayClaimHold = Duration(seconds: 30);
const statusChanged = 'This order changed. Refresh and try again.';
const packFirst = 'Pack the order before sending it out.';
const notOut = 'This order is not out for delivery.';
const notYours = 'This delivery is assigned to someone else.';
const cancelClosed = 'This order can no longer be cancelled.';
const cancelEarly = 'You can cancel only before the store starts packing.';
const stepBlocked = 'This order cannot move to that step.';

String deliveryPin(String storePincode) {
  final pin = storePincode.trim();
  return pin.isEmpty ? launchPincode : pin;
}

String deliveryAreaMessage(String storeCity, {String storePincode = ''}) {
  final name = storeCity.trim().isEmpty ? 'Malur' : storeCity.trim();
  return 'Bloom delivers in $name, ${deliveryPin(storePincode)} only.';
}

/// City must match the store, and the pin must match the store pin.
String? deliveryAreaError({
  required String city,
  required String pincode,
  required String storeCity,
  String storePincode = '',
}) {
  final sameCity = city.trim().toLowerCase() == storeCity.trim().toLowerCase();
  if (sameCity && pincode.trim() == deliveryPin(storePincode)) return null;
  return deliveryAreaMessage(storeCity, storePincode: storePincode);
}

String? cartShapeError({required int lineCount, required Iterable<int> quantities}) {
  if (lineCount < 1) return cartEmpty;
  if (lineCount > maxCartLines) return cartTooBig;
  for (final qty in quantities) {
    if (qty < 1 || qty > maxLineQty) return cartQty;
  }
  return null;
}

int pricedDeliveryFee({
  required int subtotal,
  required int fee,
  required int freeAbove,
}) {
  if (subtotal <= 0 || subtotal >= freeAbove) return 0;
  return fee;
}

bool validIdempotencyKey(String key) => idempotencyKeyPattern.hasMatch(key);

/// UPI `tr` values are short and alphanumeric. The order id is already unique.
String upiTransactionRef(String orderId) {
  final cleaned = orderId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
  if (cleaned.isEmpty) return 'bloom';
  return cleaned.length <= 20 ? cleaned : cleaned.substring(0, 20);
}

String? normalizedUpiReference(String raw) {
  final value = raw.trim();
  if (!upiReferencePattern.hasMatch(value)) return null;
  return value;
}

/// A typed UPI reference is never enough. Razorpay capture is the confirmation.
String? confirmUpiError({
  required bool isOwner,
  required String paymentMethod,
  required String status,
  required String paymentStatus,
  required String reference,
}) {
  return confirmClosed;
}

/// Paid or refund-pending UPI still has money at Razorpay.
bool blocksAccountDelete({
  required String paymentMethod,
  required String paymentStatus,
}) {
  return paymentMethod == 'upi' &&
      (paymentStatus == 'paid' || paymentStatus == 'refund_pending');
}

enum GatewaySlot { empty, freshClaim, staleClaim, ready, unknown }

GatewaySlot classifyGateway(String value, DateTime now) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return GatewaySlot.empty;
  if (isRazorpayOrderId(trimmed)) return GatewaySlot.ready;
  if (!trimmed.startsWith(gatewayClaimPrefix)) return GatewaySlot.unknown;
  final at = DateTime.tryParse(trimmed.substring(gatewayClaimPrefix.length))?.toUtc();
  if (at == null) return GatewaySlot.staleClaim;
  final age = now.toUtc().difference(at);
  if (age.isNegative || age >= gatewayClaimHold) return GatewaySlot.staleClaim;
  return GatewaySlot.freshClaim;
}

String gatewayClaimAt(DateTime now) =>
    '$gatewayClaimPrefix${now.toUtc().toIso8601String()}';

/// `processed` means the money moved. `pending` means Razorpay accepted it.
String? refundProgress(String status) {
  if (status == 'processed' || status == 'pending') return status;
  return null;
}

String? cancelError({required String actor, required String status}) {
  const customer = {'placed', 'payment_pending'};
  const owner = {'placed', 'packing', 'out_for_delivery', 'payment_pending'};
  if (actor == 'customer' && customer.contains(status)) return null;
  if (actor == 'owner' && owner.contains(status)) return null;
  if (actor == 'customer') return cancelEarly;
  return cancelClosed;
}

/// Paid UPI becomes a refund. Unpaid UPI becomes failed. Cash stays as it was.
String paymentStatusAfterCancel({
  required String status,
  required String paymentMethod,
  required String paymentStatus,
}) {
  if (status == 'payment_pending') return 'failed';
  if (paymentMethod == 'upi' && paymentStatus == 'paid') return 'refund_pending';
  return paymentStatus;
}

String? advanceError({required String from, required String to}) {
  if (from == 'placed' && to == 'packing') return null;
  if (from == 'out_for_delivery' && to == 'delivered') return null;
  return stepBlocked;
}

String? assignError(String status) {
  if (status == 'packing' || status == 'out_for_delivery') return null;
  return packFirst;
}

String? deliverError({
  required bool isOwner,
  required bool isRider,
  required bool riderMatches,
  required String status,
}) {
  if (status != 'out_for_delivery') return notOut;
  if (isOwner || (isRider && riderMatches)) return null;
  return notYours;
}

bool upiIsStale({
  required String status,
  required String method,
  required DateTime placedAt,
  required DateTime now,
}) {
  if (status != 'payment_pending' || method != 'upi') return false;
  return !now.isBefore(placedAt.add(upiHold));
}

bool morePages(int fetched, {int pageSize = deletePageSize}) => fetched >= pageSize;

bool validCoord(double value, {required bool latitude}) {
  if (!value.isFinite) return false;
  if (latitude) return value >= -90 && value <= 90;
  return value >= -180 && value <= 180;
}

bool sessionIsFresh(String createdAtIso, DateTime now) {
  final created = DateTime.tryParse(createdAtIso)?.toUtc();
  if (created == null) return false;
  final age = now.toUtc().difference(created);
  return !age.isNegative && age <= reauthWindow;
}

bool countsAsRevenue({
  required String status,
  required String paymentStatus,
  required DateTime placedAt,
  required DateTime now,
}) {
  final placed = placedAt.toLocal();
  final day = now.toLocal();
  if (placed.year != day.year || placed.month != day.month || placed.day != day.day) {
    return false;
  }
  if (status == 'cancelled' || status == 'payment_pending') return false;
  if (paymentStatus == 'refund_pending' ||
      paymentStatus == 'refunded' ||
      paymentStatus == 'failed' ||
      paymentStatus == 'pending' ||
      paymentStatus == 'submitted') {
    return false;
  }
  return paymentStatus == 'paid';
}

String? reviewCreateError({
  required bool isCustomer,
  required bool ownsOrder,
  required String status,
  required bool alreadyReviewed,
}) {
  if (!isCustomer || !ownsOrder) return 'Only the customer can review this order.';
  if (status != 'delivered') return 'Review the order after it is delivered.';
  if (alreadyReviewed) return 'This order already has a review.';
  return null;
}

/// Cash is collected when the order is delivered. UPI was already marked paid.
String? paymentStatusOnDeliver({
  required String paymentMethod,
  required String paymentStatus,
}) {
  if (paymentMethod == 'cod' && paymentStatus == 'pending') return 'paid';
  return null;
}

const onlinePayNotSetUp = 'Online payment is not set up yet.';
const paymentNotChecked = 'Payment could not be checked.';
const paymentNotConfirmed = 'Payment could not be confirmed.';
const paymentNotCaptured = 'Payment was not captured.';
const paymentAmountMismatch = 'Payment amount does not match.';
const paymentOrderMismatch = 'Payment does not match this order.';

final razorpayOrderIdPattern = RegExp(r'^order_[A-Za-z0-9]+$');
final razorpayPaymentIdPattern = RegExp(r'^pay_[A-Za-z0-9]+$');

bool isRazorpayOrderId(String value) => razorpayOrderIdPattern.hasMatch(value);

bool isRazorpayPaymentId(String value) => razorpayPaymentIdPattern.hasMatch(value);

class RazorpayKeys {
  const RazorpayKeys({
    required this.keyId,
    required this.keySecret,
    required this.webhookSecret,
  });

  final String keyId;
  final String keySecret;
  final String webhookSecret;

  bool get ready => keyId.startsWith('rzp_') && keySecret.isNotEmpty;
}

RazorpayKeys razorpayKeys(Map<String, String> env) {
  return RazorpayKeys(
    keyId: (env['RAZORPAY_KEY_ID'] ?? '').trim(),
    keySecret: (env['RAZORPAY_KEY_SECRET'] ?? '').trim(),
    webhookSecret: (env['RAZORPAY_WEBHOOK_SECRET'] ?? '').trim(),
  );
}

String razorpayHex({required String secret, required String message}) {
  final mac = Hmac(sha256, utf8.encode(secret));
  return mac.convert(utf8.encode(message)).toString();
}

bool sameSignature(String left, String right) {
  final a = utf8.encode(left.trim().toLowerCase());
  final b = utf8.encode(right.trim().toLowerCase());
  if (a.length != b.length || a.isEmpty) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

String? checkoutSignatureError({
  required String secret,
  required String orderId,
  required String paymentId,
  required String signature,
}) {
  if (secret.isEmpty ||
      !isRazorpayOrderId(orderId) ||
      !isRazorpayPaymentId(paymentId) ||
      signature.trim().isEmpty) {
    return paymentNotChecked;
  }
  final expected = razorpayHex(secret: secret, message: '$orderId|$paymentId');
  if (!sameSignature(expected, signature)) return paymentNotChecked;
  return null;
}

bool razorpayWebhookMatches({
  required String secret,
  required String rawBody,
  required String signature,
}) {
  if (secret.isEmpty || rawBody.isEmpty || signature.trim().isEmpty) return false;
  final expected = razorpayHex(secret: secret, message: rawBody);
  return sameSignature(expected, signature);
}

bool isRazorpayEventBody(String raw) {
  final trimmed = raw.trim();
  if (!trimmed.startsWith('{')) return false;
  try {
    final decoded = jsonDecode(trimmed);
    final event = razorpayEventName(decoded);
    return event != null &&
        (event.startsWith('payment.') || event.startsWith('refund.'));
  } on FormatException {
    return false;
  }
}

String? razorpayEventName(Object? decoded) {
  if (decoded is! Map) return null;
  final event = decoded['event']?.toString() ?? '';
  if (event.isEmpty) return null;
  return event;
}

class CapturedPaymentNotice {
  const CapturedPaymentNotice({
    required this.paymentId,
    required this.orderId,
    required this.amountPaise,
    required this.status,
    required this.bloomOrderId,
  });

  final String paymentId;
  final String orderId;
  final int amountPaise;
  final String status;
  final String bloomOrderId;
}

int readPaise(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse('${value ?? ''}') ?? -1;
}

CapturedPaymentNotice? capturedPaymentNotice(Object? decoded) {
  if (razorpayEventName(decoded) != 'payment.captured') return null;
  if (decoded is! Map) return null;
  final payload = decoded['payload'];
  if (payload is! Map) return null;
  final payment = payload['payment'];
  if (payment is! Map) return null;
  final entity = payment['entity'];
  if (entity is! Map) return null;
  final notes = entity['notes'];
  final bloomOrderId = notes is Map ? '${notes['bloomOrderId'] ?? ''}'.trim() : '';
  return CapturedPaymentNotice(
    paymentId: '${entity['id'] ?? ''}'.trim(),
    orderId: '${entity['order_id'] ?? ''}'.trim(),
    amountPaise: readPaise(entity['amount']),
    status: '${entity['status'] ?? ''}'.trim(),
    bloomOrderId: bloomOrderId,
  );
}

class RefundNotice {
  const RefundNotice({
    required this.paymentId,
    required this.refundId,
    required this.status,
    required this.bloomOrderId,
  });

  final String paymentId;
  final String refundId;
  final String status;
  final String bloomOrderId;
}

RefundNotice? refundProcessedNotice(Object? decoded) {
  if (razorpayEventName(decoded) != 'refund.processed') return null;
  if (decoded is! Map) return null;
  final payload = decoded['payload'];
  if (payload is! Map) return null;
  final refund = payload['refund'];
  final refundEntity = refund is Map ? refund['entity'] : null;
  if (refundEntity is! Map) return null;
  final payment = payload['payment'];
  final paymentEntity = payment is Map ? payment['entity'] : null;
  final notes = paymentEntity is Map ? paymentEntity['notes'] : null;
  final bloomOrderId = notes is Map ? '${notes['bloomOrderId'] ?? ''}'.trim() : '';
  return RefundNotice(
    paymentId: '${refundEntity['payment_id'] ?? ''}'.trim(),
    refundId: '${refundEntity['id'] ?? ''}'.trim(),
    status: '${refundEntity['status'] ?? ''}'.trim(),
    bloomOrderId: bloomOrderId,
  );
}

String? captureAcceptError({
  required String status,
  required int amountPaise,
  required int expectedRupees,
  required String razorpayOrderId,
  required String expectedOrderId,
}) {
  if (status != 'captured') return paymentNotCaptured;
  if (expectedRupees < 1 || amountPaise != expectedRupees * 100) {
    return paymentAmountMismatch;
  }
  if (!isRazorpayOrderId(razorpayOrderId) || razorpayOrderId != expectedOrderId) {
    return paymentOrderMismatch;
  }
  return null;
}

enum CaptureDecision { markPaid, alreadyPaid, lateAfterCancel, ignore }

CaptureDecision captureDecision({
  required String orderStatus,
  required String paymentStatus,
}) {
  if (paymentStatus == 'paid') return CaptureDecision.alreadyPaid;
  if (orderStatus == 'cancelled') return CaptureDecision.lateAfterCancel;
  if (orderStatus == 'payment_pending') return CaptureDecision.markPaid;
  return CaptureDecision.ignore;
}
