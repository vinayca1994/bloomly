/// Delivery fee for a cart subtotal, in rupees.
///
/// A subtotal of zero has no fee. At or above [freeAbove], delivery is free.
int deliveryFeeFor(
  int subtotal, {
  int fee = 25,
  int freeAbove = 199,
}) {
  if (subtotal <= 0) return 0;
  if (subtotal >= freeAbove) return 0;
  return fee;
}

int billTotal(int subtotal, {int fee = 25, int freeAbove = 199}) {
  return subtotal + deliveryFeeFor(subtotal, fee: fee, freeAbove: freeAbove);
}
