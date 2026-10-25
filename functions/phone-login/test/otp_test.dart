import 'dart:convert';

import 'package:phone_login/otp.dart';
import 'package:test/test.dart';

void main() {
  test('hash changes with the pepper, user, and code', () {
    const base = {'pepper': 'salt', 'userId': 'user-1', 'code': '123456'};
    final first = codeHash(
        pepper: base['pepper']!, userId: base['userId']!, code: base['code']!);
    expect(first.length, 64);
    expect(sameHash(first, first), isTrue);
    expect(
      sameHash(
          first,
          codeHash(
              pepper: 'other', userId: base['userId']!, code: base['code']!)),
      isFalse,
    );
    expect(
      sameHash(
          first,
          codeHash(
              pepper: base['pepper']!, userId: 'user-2', code: base['code']!)),
      isFalse,
    );
    expect(
      sameHash(
          first,
          codeHash(
              pepper: base['pepper']!,
              userId: base['userId']!,
              code: '654321')),
      isFalse,
    );
    expect(sameHash(first, '${first}x'), isFalse);
  });

  test('cooldown lasts 30 seconds and the code lasts 10 minutes', () {
    expect(otpCooldown, const Duration(seconds: 30));
    expect(otpLifetime, const Duration(minutes: 10));
    expect(otpMaxAttempts, 5);
    expect(cooldownError(sentAtMillis: 1000, nowMillis: 1000 + 29999), otpWait);
    expect(cooldownError(sentAtMillis: 1000, nowMillis: 1000 + 30000), isNull);
    expect(cooldownError(sentAtMillis: 0, nowMillis: 5000), isNull);
    expect(isExpired(expiresAtMillis: 5000, nowMillis: 5000), isTrue);
    expect(isExpired(expiresAtMillis: 5001, nowMillis: 5000), isFalse);
  });

  test('WhatsApp payload carries the code in the body and the button', () {
    final body = whatsAppBody(
      integratedNumber: '919000000000',
      template: 'bloom_login',
      namespace: 'ns',
      language: 'en',
      phone: '+919876543210',
      code: '654321',
    );
    final encoded = jsonEncode(body);
    expect(encoded.contains('authkey'), isFalse);
    final template = (body['payload'] as Map)['template'] as Map;
    final target = (template['to_and_components'] as List).first as Map;
    expect(target['to'], ['919876543210']);
    final components = target['components'] as Map;
    expect((components['body_1'] as Map)['value'], '654321');
    expect((components['button_1'] as Map)['value'], '654321');
  });

  test('live WhatsApp stays off until every function variable is set', () {
    const pepper = '0123456789abcdef0123456789abcdef';
    const env = {
      'OTP_PEPPER': pepper,
      'MSG91_AUTH_KEY': 'key',
      'MSG91_WHATSAPP_NUMBER': '919000000000',
      'MSG91_WHATSAPP_TEMPLATE': 'bloom_login',
      'MSG91_WHATSAPP_NAMESPACE': 'ns',
      'MSG91_WHATSAPP_LANGUAGE': 'en',
    };
    expect(pepper.length, greaterThanOrEqualTo(minPepperLength));
    expect(whatsAppReady(env), isTrue);
    expect(whatsAppReady({...env, 'MSG91_AUTH_KEY': ''}), isFalse);
    expect(whatsAppReady({...env, 'OTP_PEPPER': 'salt'}), isFalse);
    expect(pepperFor(configured: '', phone: '+919876543210'), isEmpty);
    expect(pepperFor(configured: 'salt', phone: '+919876543210'), isEmpty);
    expect(pepperFor(configured: '', phone: mockPhone), isEmpty);
    expect(pepperFor(configured: '', phone: mockPhone, mockEnabled: true), mockPepper);
    expect(pepperFor(configured: pepper, phone: mockPhone, mockEnabled: true), pepper);
    expect(mockOtpEnabled(const {'OTP_MOCK': '1'}), isTrue);
    expect(mockOtpEnabled(const {}), isFalse);
    expect(isMockPhone(mockPhone), isTrue);
  });

  test('a phone can request five codes an hour, and a raced attempt loses', () {
    final first = claimSend(windowStart: 0, sendCount: 0, nowMillis: 1000);
    expect(first.allowed, isTrue);
    expect(first.sendCount, 1);
    final fifth = claimSend(windowStart: 1000, sendCount: 4, nowMillis: 2000);
    expect(fifth.allowed, isTrue);
    expect(fifth.sendCount, 5);
    final blocked = claimSend(windowStart: 1000, sendCount: 5, nowMillis: 2000);
    expect(blocked.allowed, isFalse);
    final reset = claimSend(
      windowStart: 1000,
      sendCount: 5,
      nowMillis: 1000 + otpSendWindow.inMilliseconds,
    );
    expect(reset.allowed, isTrue);
    expect(reset.sendCount, 1);
    expect(nextAttempt(attempts: 4).blocked, isFalse);
    expect(nextAttempt(attempts: 5).blocked, isTrue);
    expect(sendLimitId('+919876543210'), isNot(sendLimitId(mockPhone)));
  });
}
