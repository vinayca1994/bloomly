import 'package:bloomly/core/sign_in_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('only shop paths survive the return link', () {
    expect(safeReturnPath('/checkout'), '/checkout');
    expect(safeReturnPath('/owner/orders'), '/owner/orders');
    expect(safeReturnPath('//evil.example'), isNull);
    expect(safeReturnPath('https://evil.example'), isNull);
    expect(safeReturnPath('/account/../../etc'), isNull);
  });

  test('the owner lands in the store unless they were checking out', () {
    expect(
      landingAfterSignIn(role: 'owner', next: null).location,
      '/owner',
    );
    expect(
      landingAfterSignIn(role: 'owner', next: '/owner/orders').location,
      '/owner/orders',
    );
    expect(
      landingAfterSignIn(role: 'owner', next: '/checkout').location,
      '/checkout',
    );
  });

  test('a rider always opens deliveries', () {
    expect(
      landingAfterSignIn(role: 'rider', next: '/owner').location,
      '/rider',
    );
  });

  test('a customer cannot open the store or rider console', () {
    final store = landingAfterSignIn(role: 'customer', next: '/owner');
    expect(store.location, '/account');
    expect(store.notice, isNotNull);
    expect(
      landingAfterSignIn(role: 'customer', next: '/checkout').location,
      '/checkout',
    );
    expect(landingAfterSignIn(role: 'customer', next: null).location, '/');
  });
}
