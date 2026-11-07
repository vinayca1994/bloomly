import 'package:bloomly/core/phone.dart';
import 'package:bloomly/core/upi.dart';
import 'package:bloomly/data/auth_result.dart';
import 'package:bloomly/data/memory_backend.dart';
import 'package:bloomly/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('indian mobile numbers become E.164', () {
    expect(PhoneNumber.normalizeIndia('9876543210'), '+919876543210');
    expect(PhoneNumber.normalizeIndia('+91 98765 43210'), '+919876543210');
    expect(PhoneNumber.normalizeIndia('09876543210'), '+919876543210');
    expect(PhoneNumber.normalizeIndia('919876543210'), '+919876543210');
    expect(PhoneNumber.normalizeIndia('5876543210'), isNull);
    expect(PhoneNumber.normalizeIndia('12345'), isNull);
  });

  test('a customer cannot mark a UPI payment as paid', () async {
    final backend = MemoryBackend.seeded(upiId: 'bloomly@oksbi');
    await backend.signIn(
      MemoryBackend.customerEmail,
      MemoryBackend.demoPassword,
    );
    final address = backend.addressesFor('customer-demo').first;
    final started = await backend.startOnlinePayment(
      userId: 'customer-demo',
      address: address,
      lines: const [
        CartLine(productId: 'tomato', variantId: 'tomato-250g', qty: 2),
      ],
    );

    expect(started.order.status, OrderStatus.paymentPending);
    expect(started.order.paymentMethod, PaymentMethod.upi);
    expect(started.order.subtotal, 36);
    expect(started.opensGateway, isFalse);
    expect(started.amountRupees, 61);

    expect(
      await backend.noteUpiPayment(
        orderId: started.order.id,
        reference: 'not a ref',
      ),
      isNotNull,
    );
    expect(await backend.confirmUpiPayment(started.order.id), isNotNull);
    final order = backend.orderById(started.order.id)!;
    expect(order.status, OrderStatus.paymentPending);
    expect(order.paymentStatus, PaymentStatus.pending);
    expect(OrderStatus.visibleToStore(order.status), isFalse);
  });

  test('the store cannot confirm a UPI reference, and cash stays unpaid', () async {
    final backend = MemoryBackend.seeded(
      upiId: 'bloomly@oksbi',
      upiName: 'Bloomly',
    );
    final address = backend.addressesFor('customer-demo').first;
    final cash = await backend.placeOrder(
      userId: 'customer-demo',
      address: address,
      lines: const [
        CartLine(productId: 'tomato', variantId: 'tomato-250g', qty: 1),
      ],
    );
    expect(cash.status, OrderStatus.placed);
    expect(cash.paymentMethod, PaymentMethod.cod);
    expect(cash.paymentStatus, PaymentStatus.pending);
    expect(cash.subtotal, 18);

    await backend.signIn(
      MemoryBackend.customerEmail,
      MemoryBackend.demoPassword,
    );
    final started = await backend.startOnlinePayment(
      userId: 'customer-demo',
      address: address,
      lines: const [
        CartLine(productId: 'tomato', variantId: 'tomato-1kg', qty: 4),
      ],
    );
    expect(started.order.subtotal, 216);
    expect(started.order.deliveryFee, 0);
    expect(
      await backend.noteUpiPayment(
        orderId: started.order.id,
        reference: '123456789012',
      ),
      isNotNull,
    );
    final sent = backend.orderById(started.order.id)!;
    expect(sent.paymentStatus, PaymentStatus.pending);
    expect(sent.status, OrderStatus.paymentPending);
    expect(OrderStatus.visibleToStore(sent.status), isFalse);

    await backend.signIn(MemoryBackend.ownerEmail, MemoryBackend.demoPassword);
    expect(await backend.confirmUpiPayment(started.order.id), isNotNull);
    final stillWaiting = backend.orderById(started.order.id)!;
    expect(stillWaiting.status, OrderStatus.paymentPending);
    expect(stillWaiting.paymentStatus, PaymentStatus.pending);
  });

  test('the in-memory shop marks UPI paid without a bank', () async {
    final backend = MemoryBackend.seeded(upiId: 'bloomly@oksbi');
    expect(backend.usesTestCheckout, isTrue);
    final address = backend.addressesFor('customer-demo').first;
    final started = await backend.startOnlinePayment(
      userId: 'customer-demo',
      address: address,
      lines: const [
        CartLine(productId: 'tomato', variantId: 'tomato-250g', qty: 1),
      ],
    );
    expect(started.opensGateway, isFalse);
    expect(await backend.completeTestPayment(started.order.id), isNull);
    final paid = backend.orderById(started.order.id)!;
    expect(paid.status, OrderStatus.placed);
    expect(paid.paymentStatus, PaymentStatus.paid);
    expect(
      await backend.verifyOnlinePayment(
        orderId: paid.id,
        razorpayOrderId: 'order_1',
        razorpayPaymentId: 'pay_1',
        signature: 'nope',
      ),
      isNotNull,
    );
  });

  test('a UPI link uses rupees and rejects a bad ID', () {
    final uri = upiPayUri(
      vpa: 'bloomly@oksbi',
      name: 'Bloomly',
      amountRupees: 43,
      note: 'Bloomly ord1',
    );
    expect(
      uri,
      'upi://pay?pa=bloomly%40oksbi&pn=Bloomly&am=43.00&cu=INR&tn=Bloomly+ord1',
    );
    expect(
      upiPayUri(
        vpa: 'not-a-upi-id',
        name: 'Bloomly',
        amountRupees: 43,
        note: '',
      ),
      isNull,
    );
    expect(normalizeUpiReference(''), '');
    expect(normalizeUpiReference('abc 1'), isNull);
  });

  test('each UPI app link carries the ID, amount, and reference', () {
    for (final app in upiApps) {
      final link = upiAppLink(
        app: app,
        android: false,
        vpa: 'bloomly@oksbi',
        name: 'Bloomly',
        amountRupees: 43,
        note: 'Bloom ord1',
        transactionRef: 'ord1',
      );
      expect(link, isNotNull);
      expect(link, contains('pa=bloomly%40oksbi'));
      expect(link, contains('am=43.00'));
      expect(link, contains('tr=ord1'));
    }
    final gpay = upiAppLink(
      app: upiApps.first,
      android: true,
      vpa: 'bloomly@oksbi',
      name: 'Bloomly',
      amountRupees: 43,
      note: 'Bloom ord1',
      transactionRef: 'ord1',
    );
    expect(gpay, startsWith('intent://pay?'));
    expect(gpay, contains('package=com.google.android.apps.nbu.paisa.user'));
    expect(gpay, contains('am=43.00'));
    expect(gpay, contains('tr=ord1'));
    expect(
      upiAppLink(
        app: upiApps.first,
        android: true,
        vpa: 'not-a-upi-id',
        name: 'Bloomly',
        amountRupees: 43,
        note: '',
      ),
      isNull,
    );
  });

  test('Malur with another pin is outside the launch area', () async {
    final backend = MemoryBackend.seeded();
    const address = Address(
      id: 'other-pin',
      userId: 'customer-demo',
      label: 'Home',
      line: '1 Main Road',
      area: 'Malur',
      city: 'Malur',
      pincode: '563160',
      isDefault: false,
    );
    expect(
      () => backend.placeOrder(
        userId: 'customer-demo',
        address: address,
        lines: const [
          CartLine(productId: 'tomato', variantId: 'tomato-250g', qty: 1),
        ],
      ),
      throwsA(
        isA<BloomlyException>().having(
          (error) => error.message,
          'message',
          'Bloom delivers in Malur, 563130 only.',
        ),
      ),
    );
  });

  test('an address outside the store city is rejected', () async {
    final backend = MemoryBackend.seeded();
    const address = Address(
      id: 'away',
      userId: 'customer-demo',
      label: 'Work',
      line: '1 Main Road',
      area: 'Fort',
      city: 'Mumbai',
      pincode: '400001',
      isDefault: false,
    );
    expect(
      () => backend.placeOrder(
        userId: 'customer-demo',
        address: address,
        lines: const [
          CartLine(productId: 'tomato', variantId: 'tomato-250g', qty: 1),
        ],
      ),
      throwsA(isA<BloomlyException>()),
    );
  });

  test('phone sign-in accepts the demo code and rejects another', () async {
    final backend = MemoryBackend.seeded();
    final started = await backend.startPhoneLogin(
      '9876543210',
      channel: OtpChannel.sms,
    );
    expect(started.ok, isTrue);
    expect(
      await backend.verifyPhoneOtp(
        userId: started.userId!,
        code: '000000',
        channel: OtpChannel.sms,
      ),
      isNotNull,
    );
    expect(
      await backend.verifyPhoneOtp(
        userId: started.userId!,
        code: MemoryBackend.demoOtp,
        channel: OtpChannel.sms,
      ),
      isNull,
    );
    expect(backend.currentUser?.phone, '+919876543210');
    expect(backend.currentUser?.role, 'customer');
    final whatsApp = await backend.startPhoneLogin(
      '9876543211',
      channel: OtpChannel.whatsapp,
    );
    expect(whatsApp.ok, isTrue);
    expect(
      await backend.verifyPhoneOtp(
        userId: whatsApp.userId!,
        code: MemoryBackend.demoOtp,
        channel: OtpChannel.whatsapp,
      ),
      isNull,
    );
    expect(backend.currentUser?.phone, '+919876543211');
    final named = await backend.updateDisplayName('Meera');
    expect(named, isNull);
    expect(backend.currentUser?.name, 'Meera');
  });

  test('email sign-in accepts the demo code and rejects another', () async {
    final backend = MemoryBackend.seeded();
    final started = await backend.startEmailLogin('new.shopper@gmail.com');
    expect(started.ok, isTrue);
    expect(
      await backend.verifyEmailOtp(userId: started.userId!, code: '000000'),
      isNotNull,
    );
    expect(
      await backend.verifyEmailOtp(
        userId: started.userId!,
        code: MemoryBackend.demoOtp,
      ),
      isNull,
    );
    expect(backend.currentUser?.email, 'new.shopper@gmail.com');
    expect(backend.currentUser?.name, '');
    expect(backend.currentUser?.role, 'customer');
    final named = await backend.updateDisplayName('Meera');
    expect(named, isNull);
    expect(backend.currentUser?.name, 'Meera');
    final again = await backend.startEmailLogin('New.Shopper@gmail.com');
    expect(again.userId, backend.currentUser?.id);
    expect(
      await backend.verifyEmailOtp(
        userId: again.userId!,
        code: MemoryBackend.demoOtp,
      ),
      isNull,
    );
    expect(backend.currentUser?.name, 'Meera');
    expect((await backend.startEmailLogin('not-an-email')).ok, isFalse);
  });
}
