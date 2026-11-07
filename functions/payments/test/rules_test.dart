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
    expect(
      deliveryAreaError(city: 'Malur', pincode: '563130', storeCity: 'Malur'),
      isNull,
    );
    expect(
      deliveryAreaError(city: 'Malur', pincode: '563160', storeCity: 'Malur'),
      'Bloom delivers in Malur, 563130 only.',
    );
    expect(
      deliveryAreaError(city: 'Mumbai', pincode: '400001', storeCity: 'Malur'),
      'Bloom delivers in Malur, 563130 only.',
    );
  });

  test('a typed UPI reference is never confirmed by the store', () {
    expect(
      confirmUpiError(
        isOwner: true,
        paymentMethod: 'upi',
        status: 'payment_pending',
        paymentStatus: 'submitted',
        reference: 'ABC123',
      ),
      confirmClosed,
    );
    expect(
      blocksAccountDelete(paymentMethod: 'upi', paymentStatus: 'paid'),
      isTrue,
    );
    expect(
      blocksAccountDelete(paymentMethod: 'upi', paymentStatus: 'refund_pending'),
      isTrue,
    );
    expect(
      blocksAccountDelete(paymentMethod: 'cod', paymentStatus: 'paid'),
      isFalse,
    );
    expect(
      blocksAccountDelete(paymentMethod: 'upi', paymentStatus: 'refunded'),
      isFalse,
    );
    final now = DateTime.utc(2026, 11, 7, 12);
    expect(classifyGateway('', now), GatewaySlot.empty);
    expect(classifyGateway('order_abc', now), GatewaySlot.ready);
    expect(
      classifyGateway(gatewayClaimAt(now), now),
      GatewaySlot.freshClaim,
    );
    expect(
      classifyGateway(gatewayClaimAt(now.subtract(const Duration(minutes: 2))), now),
      GatewaySlot.staleClaim,
    );
    expect(refundProgress('processed'), 'processed');
    expect(refundProgress('failed'), isNull);
    expect(
      deliveryAreaError(
        city: 'Malur',
        pincode: '563130',
        storeCity: 'Bengaluru',
        storePincode: '560001',
      ),
      'Bloom delivers in Bengaluru, 560001 only.',
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

  test('a Razorpay signature matches the order and payment', () {
    const secret = 'secret';
    const orderId = 'order_1';
    const paymentId = 'pay_1';
    final signature = razorpayHex(secret: secret, message: '$orderId|$paymentId');
    expect(
      signature,
      '52115a0d3400de9e86aade1f1b6eba9e8974604f4e267a9e9a16633a4c8dd2cb',
    );
    expect(
      checkoutSignatureError(
        secret: secret,
        orderId: orderId,
        paymentId: paymentId,
        signature: signature,
      ),
      isNull,
    );
    expect(
      checkoutSignatureError(
        secret: secret,
        orderId: orderId,
        paymentId: paymentId,
        signature: 'nope',
      ),
      paymentNotChecked,
    );
    const raw = '{"event":"payment.captured"}';
    final hook = razorpayHex(secret: 'whsec', message: raw);
    expect(razorpayWebhookMatches(secret: 'whsec', rawBody: raw, signature: hook), isTrue);
    expect(
      razorpayWebhookMatches(secret: 'whsec', rawBody: '$raw ', signature: hook),
      isFalse,
    );
    expect(isRazorpayEventBody(raw), isTrue);
    expect(isRazorpayEventBody('{"event":"refund.processed"}'), isTrue);
    expect(isRazorpayEventBody('{"action":"create"}'), isFalse);
  });

  test('a capture is accepted only for the same paise amount', () {
    expect(
      captureAcceptError(
        status: 'captured',
        amountPaise: 6100,
        expectedRupees: 61,
        razorpayOrderId: 'order_1',
        expectedOrderId: 'order_1',
      ),
      isNull,
    );
    expect(
      captureAcceptError(
        status: 'authorized',
        amountPaise: 6100,
        expectedRupees: 61,
        razorpayOrderId: 'order_1',
        expectedOrderId: 'order_1',
      ),
      paymentNotCaptured,
    );
    expect(
      captureAcceptError(
        status: 'captured',
        amountPaise: 100,
        expectedRupees: 61,
        razorpayOrderId: 'order_1',
        expectedOrderId: 'order_1',
      ),
      paymentAmountMismatch,
    );
    expect(
      captureDecision(orderStatus: 'payment_pending', paymentStatus: 'pending'),
      CaptureDecision.markPaid,
    );
    expect(
      captureDecision(orderStatus: 'placed', paymentStatus: 'paid'),
      CaptureDecision.alreadyPaid,
    );
    expect(
      captureDecision(orderStatus: 'cancelled', paymentStatus: 'failed'),
      CaptureDecision.lateAfterCancel,
    );
    expect(razorpayKeys(const {}).ready, isFalse);
    expect(
      razorpayKeys(const {'RAZORPAY_KEY_ID': 'rzp_test_x', 'RAZORPAY_KEY_SECRET': 's'}).ready,
      isTrue,
    );
    final notice = capturedPaymentNotice({
      'event': 'payment.captured',
      'payload': {
        'payment': {
          'entity': {
            'id': 'pay_1',
            'order_id': 'order_1',
            'amount': 6100,
            'status': 'captured',
            'notes': {'bloomOrderId': 'ord1'},
          },
        },
      },
    });
    expect(notice?.paymentId, 'pay_1');
    expect(notice?.bloomOrderId, 'ord1');
    expect(notice?.amountPaise, 6100);
    expect(capturedPaymentNotice({'event': 'payment.failed'}), isNull);
    final refund = refundProcessedNotice({
      'event': 'refund.processed',
      'payload': {
        'refund': {
          'entity': {
            'id': 'rfnd_1',
            'payment_id': 'pay_1',
            'status': 'processed',
          },
        },
        'payment': {
          'entity': {
            'notes': {'bloomOrderId': 'ord1'},
          },
        },
      },
    });
    expect(refund?.paymentId, 'pay_1');
    expect(refund?.bloomOrderId, 'ord1');
    expect(refund?.status, 'processed');
  });
}
