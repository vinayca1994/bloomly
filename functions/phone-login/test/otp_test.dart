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

  test('cooldown lasts 30 seconds and the code lasts 15 minutes', () {
    expect(otpCooldown, const Duration(seconds: 30));
    expect(otpLifetime, const Duration(minutes: 15));
    expect(otpMaxAttempts, 5);
    expect(cooldownError(sentAtMillis: 1000, nowMillis: 1000 + 29999), otpWait);
    expect(cooldownError(sentAtMillis: 1000, nowMillis: 1000 + 30000), isNull);
    expect(cooldownError(sentAtMillis: 0, nowMillis: 5000), isNull);
    expect(isExpired(expiresAtMillis: 5000, nowMillis: 5000), isTrue);
    expect(isExpired(expiresAtMillis: 5001, nowMillis: 5000), isFalse);
  });

  test('WhatsApp OTP uses loomWhatsAppOTP for 6 digits and 15 minutes', () {
    final body = msg91OtpBody(
      template: whatsAppTemplate(const {}),
      phone: '+919876543210',
      code: '654321',
    );
    expect(jsonEncode(body).contains('authkey'), isFalse);
    expect(body['template_id'], whatsAppTemplateName);
    expect(body['mobile'], '919876543210');
    expect(body['otp'], '654321');
    expect(body['otp_length'], 6);
    expect(body['otp_expiry'], 15);
    expect(
      whatsAppTemplate(const {'MSG91_WHATSAPP_TEMPLATE': 'other'}),
      'other',
    );
  });

  test('live WhatsApp stays off until the pepper and MSG91 key are set', () {
    const pepper = '0123456789abcdef0123456789abcdef';
    const env = {
      'OTP_PEPPER': pepper,
      'MSG91_AUTH_KEY': 'key',
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
    final global = claimSend(
      windowStart: 1000,
      sendCount: otpGlobalSendLimit,
      nowMillis: 2000,
      limit: otpGlobalSendLimit,
    );
    expect(global.allowed, isFalse);
    expect(globalSendLimitId, 'otpglobal');
  });
}
