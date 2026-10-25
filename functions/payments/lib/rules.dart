/// Decisions the payments function can make without Appwrite.
const maxCartLines = 40;
const maxLineQty = 99;
const upiHold = Duration(minutes: 45);
const deletePageSize = 100;
const reauthWindow = Duration(minutes: 5);

final idempotencyKeyPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$');
final upiReferencePattern = RegExp(r'^[A-Za-z0-9]{1,35}$');

const cartTooBig = 'Too many items in the cart.';
const cartQty = 'Check the quantities in your cart.';
const cartEmpty = 'Add an address and at least one item.';
const confirmWait = 'Wait for the customer’s UPI reference before confirming.';
const confirmNotWaiting = 'This order is not awaiting a UPI payment.';
const confirmNotUpi = 'This order was not paid by UPI.';
const confirmOwner = 'Only the store can confirm a UPI payment.';
const statusChanged = 'This order changed. Refresh and try again.';
const packFirst = 'Pack the order before sending it out.';
const notOut = 'This order is not out for delivery.';
const notYours = 'This delivery is assigned to someone else.';
const cancelClosed = 'This order can no longer be cancelled.';
const cancelEarly = 'You can cancel only before the store starts packing.';
const stepBlocked = 'This order cannot move to that step.';

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

String? confirmUpiError({
  required bool isOwner,
  required String paymentMethod,
  required String status,
  required String paymentStatus,
  required String reference,
}) {
  if (!isOwner) return confirmOwner;
  if (paymentMethod != 'upi') return confirmNotUpi;
  if (status != 'payment_pending') return confirmNotWaiting;
  if (paymentStatus != 'submitted') return confirmWait;
  if (normalizedUpiReference(reference) == null) return confirmWait;
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
