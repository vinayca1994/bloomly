import 'package:bloomly/data/memory_backend.dart';
import 'package:bloomly/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a customer cannot assign a rider', () async {
    final backend = MemoryBackend.seeded();
    final address = backend.addressesFor('customer-demo').first;
    final order = await backend.placeOrder(
      userId: 'customer-demo',
      address: address,
      lines: const [CartLine(productId: 'tomato', variantId: 'tomato-250g', qty: 1)],
    );
    await backend.signIn(MemoryBackend.customerEmail, MemoryBackend.demoPassword);

    expect(
      await backend.assignRider(orderId: order.id, riderId: 'rider-demo'),
      'Only the store can assign a rider.',
    );
    final unchanged = backend.orderById(order.id)!;
    expect(unchanged.status, OrderStatus.placed);
    expect(unchanged.riderId, isEmpty);
    expect(unchanged.total, order.total);
  });

  test('a review is once and scores stay between 1 and 5', () async {
    final backend = MemoryBackend.seeded();
    final address = backend.addressesFor('customer-demo').first;
    final order = await backend.placeOrder(
      userId: 'customer-demo',
      address: address,
      lines: const [CartLine(productId: 'tomato', variantId: 'tomato-250g', qty: 1)],
    );
    await backend.signIn(MemoryBackend.ownerEmail, MemoryBackend.demoPassword);
    expect(await backend.updateOrderStatus(order.id, OrderStatus.packing), isNull);
    expect(await backend.assignRider(orderId: order.id, riderId: 'rider-demo'), isNull);

    await backend.signIn(MemoryBackend.riderEmail, MemoryBackend.demoPassword);
    expect(
      await backend.updateRiderLocation(orderId: order.id, latitude: 12.97, longitude: 77.59),
      isNull,
    );
    final moving = backend.orderById(order.id)!;
    expect(moving.total, order.total);
    expect(moving.status, OrderStatus.outForDelivery);
    expect(backend.locationFor(order.id)?.latitude, 12.97);
    expect(await backend.markDelivered(order.id), isNull);

    await backend.signIn(MemoryBackend.customerEmail, MemoryBackend.demoPassword);
    expect(
      await backend.submitReview(
        orderId: order.id,
        freshness: 6,
        rightItems: 5,
        packing: 5,
        onTime: 5,
        polite: 5,
        careful: 5,
      ),
      'Choose 1 to 5 stars for each part.',
    );
    expect(backend.reviewFor(order.id), isNull);
    expect(
      await backend.submitReview(
        orderId: order.id,
        freshness: 5,
        rightItems: 4,
        packing: 5,
        onTime: 4,
        polite: 5,
        careful: 5,
        note: 'Bag was careful.',
      ),
      isNull,
    );
    expect(backend.reviewFor(order.id)?.freshness, 5);
    expect(
      await backend.submitReview(
        orderId: order.id,
        freshness: 1,
        rightItems: 1,
        packing: 1,
        onTime: 1,
        polite: 1,
        careful: 1,
      ),
      'This order already has a review.',
    );
    expect(backend.reviewFor(order.id)?.freshness, 5);
  });
}
