import 'dart:convert';
import 'dart:io';

import 'rules.dart';

class RazorpayException implements Exception {
  const RazorpayException();
}

/// Server calls to Razorpay. The key secret stays in this process.
class RazorpayApi {
  RazorpayApi({required this.keyId, required this.keySecret, HttpClient? client})
    : _client = client ?? HttpClient();

  final String keyId;
  final String keySecret;
  final HttpClient _client;

  Future<String?> createOrder({
    required int amountPaise,
    required String receipt,
    required String bloomOrderId,
  }) async {
    final body = await _send('POST', '/v1/orders', {
      'amount': amountPaise,
      'currency': 'INR',
      'receipt': receipt,
      'notes': {'bloomOrderId': bloomOrderId},
    });
    final id = '${body['id'] ?? ''}'.trim();
    if (!isRazorpayOrderId(id)) return null;
    return id;
  }

  Future<Map<String, dynamic>> fetchPayment(String paymentId) async {
    if (!isRazorpayPaymentId(paymentId)) throw const RazorpayException();
    return _send('GET', '/v1/payments/$paymentId', null);
  }

  /// Full refund of a captured payment. `status` is `processed` or `pending`.
  Future<Map<String, dynamic>> refundPayment({
    required String paymentId,
    required int amountPaise,
    required String bloomOrderId,
  }) async {
    if (!isRazorpayPaymentId(paymentId)) throw const RazorpayException();
    if (amountPaise < 100) throw const RazorpayException();
    return _send('POST', '/v1/payments/$paymentId/refund', {
      'amount': amountPaise,
      'speed': 'normal',
      'notes': {'bloomOrderId': bloomOrderId},
    });
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, Object?>? json,
  ) async {
    final uri = Uri.parse('https://api.razorpay.com$path');
    final request = method == 'POST'
        ? await _client.postUrl(uri)
        : await _client.getUrl(uri);
    request.followRedirects = false;
    final token = base64Encode(utf8.encode('$keyId:$keySecret'));
    request.headers.set(HttpHeaders.authorizationHeader, 'Basic $token');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (json != null) {
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.add(utf8.encode(jsonEncode(json)));
    }
    final response = await request.close().timeout(const Duration(seconds: 12));
    final text = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 12));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const RazorpayException();
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const RazorpayException();
    return Map<String, dynamic>.from(decoded);
  }

  void close() => _client.close(force: true);
}
