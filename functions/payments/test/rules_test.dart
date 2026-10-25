import 'package:payments/rules.dart';
import 'package:test/test.dart';

void main() {
  test('repricing uses the store fee and ignores a huge cart', () {
    expect(pricedDeliveryFee(subtotal: 100, fee: 25, freeAbove: 199), 25);
    expect(pricedDeliveryFee(subtotal: 199, fee: 25, freeAbove: 199), 0);
    expect(pricedDeliveryFee(subtotal: 0, fee: 25, freeAbove: 199), 0);
    expect(cartShapeError(lineCount: 0, quantities: const []), cartEmpty);
    expect(cartShapeError(lineCount: 41, quantities: const [1]), cartTooBig);
    expect(cartShapeError(lineCount: 1, quantities: const [100]), cartQty);
    expect(cartShapeError(lineCount: 2, quantities: const [1, 99]), isNull);
  });

  test('confirm is rejected unless the order is still awaiting a reference', () {
    expect(
      confirmUpiError(
        isOwner: false,
        paymentMethod: 'upi',
        status: 'payment_pending',
        paymentStatus: 'submitted',
        reference: 'ABC123',
      ),
      confirmOwner,
    );
    expect(
      confirmUpiError(
        isOwner: true,
        paymentMethod: 'upi',
        status: 'placed',
        paymentStatus: 'paid',
        reference: 'ABC123',
      ),
      confirmNotWaiting,
    );
    expect(
      confirmUpiError(
        isOwner: true,
        paymentMethod: 'upi',
        status: 'payment_pending',
        paymentStatus: 'pending',
        reference: '',
      ),
      confirmWait,
    );
    expect(
      confirmUpiError(
        isOwner: true,
        paymentMethod: 'upi',
        status: 'payment_pending',
        paymentStatus: 'submitted',
        reference: 'ABC123',
      ),
      isNull,
    );
  });

  test('status edges follow the packing steps', () {
    expect(cancelError(actor: 'customer', status: 'placed'), isNull);
    expect(cancelError(actor: 'customer', status: 'packing'), cancelEarly);
    expect(cancelError(actor: 'owner', status: 'out_for_delivery'), isNull);
    expect(cancelError(actor: 'owner', status: 'delivered'), cancelClosed);
    expect(
      paymentStatusAfterCancel(
        status: 'placed',
        paymentMethod: 'upi',
        paymentStatus: 'paid',
      ),
      'refund_pending',
    );
    expect(
      paymentStatusAfterCancel(
        status: 'payment_pending',
        paymentMethod: 'upi',
        paymentStatus: 'submitted',
      ),
      'failed',
    );
    expect(advanceError(from: 'placed', to: 'packing'), isNull);
    expect(advanceError(from: 'placed', to: 'delivered'), stepBlocked);
    expect(advanceError(from: 'out_for_delivery', to: 'delivered'), isNull);
    expect(assignError('placed'), packFirst);
    expect(assignError('packing'), isNull);
    expect(
      deliverError(isOwner: false, isRider: true, riderMatches: false, status: 'out_for_delivery'),
      notYours,
    );
    expect(
      deliverError(isOwner: false, isRider: true, riderMatches: true, status: 'out_for_delivery'),
      isNull,
    );
    expect(
      deliverError(isOwner: true, isRider: false, riderMatches: false, status: 'placed'),
      notOut,
    );
  });

  test('stale UPI, paging, revenue, and a fresh session', () {
    final placed = DateTime.utc(2026, 10, 24, 10);
    expect(
      upiIsStale(
        status: 'payment_pending',
        method: 'upi',
        placedAt: placed,
        now: placed.add(const Duration(minutes: 44)),
      ),
      isFalse,
    );
    expect(
      upiIsStale(
        status: 'payment_pending',
        method: 'upi',
        placedAt: placed,
        now: placed.add(upiHold),
      ),
      isTrue,
    );
    expect(morePages(100), isTrue);
    expect(morePages(99), isFalse);
    expect(morePages(0), isFalse);
    expect(
      countsAsRevenue(
        status: 'placed',
        paymentStatus: 'pending',
        placedAt: placed,
        now: placed,
      ),
      isFalse,
    );
    expect(
      countsAsRevenue(
        status: 'delivered',
        paymentStatus: 'paid',
        placedAt: placed,
        now: placed,
      ),
      isTrue,
    );
    expect(
      countsAsRevenue(
        status: 'cancelled',
        paymentStatus: 'refunded',
        placedAt: placed,
        now: placed,
      ),
      isFalse,
    );
    expect(sessionIsFresh(placed.toIso8601String(), placed.add(const Duration(minutes: 4))), isTrue);
    expect(sessionIsFresh(placed.toIso8601String(), placed.add(const Duration(minutes: 6))), isFalse);
    expect(validIdempotencyKey('order_1'), isTrue);
    expect(validIdempotencyKey(''), isFalse);
    expect(upiTransactionRef('ord_123'), 'ord123');
    expect(validCoord(12.97, latitude: true), isTrue);
    expect(validCoord(120, latitude: true), isFalse);
    expect(paymentStatusOnDeliver(paymentMethod: 'cod', paymentStatus: 'pending'), 'paid');
    expect(paymentStatusOnDeliver(paymentMethod: 'upi', paymentStatus: 'paid'), isNull);
  });
}
