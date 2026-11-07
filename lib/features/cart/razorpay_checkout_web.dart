import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

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
  final loaded = await _ensureCheckoutScript();
  if (!loaded || !globalContext.has('Razorpay')) return null;
  final completer = Completer<RazorpayCheckoutResult?>();
  void finish(RazorpayCheckoutResult? result) {
    if (!completer.isCompleted) completer.complete(result);
  }

  final options = <String, Object?>{
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
    'handler': ((JSObject response) {
      final data = response.dartify();
      if (data is! Map) {
        finish(null);
        return;
      }
      final paidOrder = '${data['razorpay_order_id'] ?? ''}';
      final paymentId = '${data['razorpay_payment_id'] ?? ''}';
      final signature = '${data['razorpay_signature'] ?? ''}';
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
    }).toJS,
    'modal': {
      'ondismiss': (() {
        finish(null);
      }).toJS,
    },
  }.jsify();
  if (options == null) {
    finish(null);
    return completer.future;
  }
  final checkout = _Razorpay(options);
  checkout.open();
  return completer.future;
}

@JS('Razorpay')
extension type _Razorpay._(JSObject _) implements JSObject {
  external _Razorpay(JSAny? options);
  external void open();
}

@JS('document')
external _Document get _document;

extension type _Document(JSObject _) implements JSObject {
  external _Element? querySelector(String selectors);
  external _Element createElement(String tag);
  external _Element get head;
}

extension type _Element(JSObject _) implements JSObject {
  external set src(String value);
  external set async(bool value);
  external set onload(JSFunction? value);
  external set onerror(JSFunction? value);
  external void setAttribute(String name, String value);
  external void appendChild(_Element child);
}

Future<bool> _ensureCheckoutScript() async {
  if (globalContext.has('Razorpay')) return true;
  if (_document.querySelector('script[data-bloom-razorpay]') != null) {
    return _waitForCtor();
  }
  final completer = Completer<bool>();
  final script = _document.createElement('script');
  script.src = 'https://checkout.razorpay.com/v1/checkout.js';
  script.async = true;
  script.setAttribute('data-bloom-razorpay', '1');
  script.onload = (() {
    if (!completer.isCompleted) completer.complete(globalContext.has('Razorpay'));
  }).toJS;
  script.onerror = (() {
    if (!completer.isCompleted) completer.complete(false);
  }).toJS;
  _document.head.appendChild(script);
  return completer.future.timeout(const Duration(seconds: 12), onTimeout: () => false);
}

Future<bool> _waitForCtor() async {
  final deadline = DateTime.now().add(const Duration(seconds: 12));
  while (DateTime.now().isBefore(deadline)) {
    if (globalContext.has('Razorpay')) return true;
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
  return false;
}
