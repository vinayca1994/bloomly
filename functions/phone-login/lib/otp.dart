import 'dart:convert';

import 'package:crypto/crypto.dart';

const mockPhone = '+919999999999';
const mockCode = '123456';
const mockPepper = 'bloom-mock-otp';

const whatsAppTemplateName = 'loomWhatsAppOTP';
const otpLifetime = Duration(minutes: 15);
const otpCooldown = Duration(seconds: 30);
const otpMaxAttempts = 5;
const otpSendLimit = 5;
const otpGlobalSendLimit = 30;
const otpSendWindow = Duration(hours: 1);
const globalSendLimitId = 'otpglobal';
const minPepperLength = 32;

const whatsAppNotSetUp = 'WhatsApp codes are not set up yet.';
const otpWait = 'Wait a few seconds before requesting another code.';
const otpWrong = 'That code is wrong.';
const otpExpired = 'That code has expired. Request a new one.';
const otpTooMany = 'Too many tries. Request a new code.';
const otpSendFailed = 'Could not send the WhatsApp code.';
const otpRequestNew = 'Request a new code.';
const otpBadPhone = 'Enter a valid 10-digit mobile number.';
const otpStartFailed = 'Could not start phone sign-in.';
const otpSendLimited = 'Too many codes. Try again in an hour.';

const _configKeys = [
  'OTP_PEPPER',
  'MSG91_AUTH_KEY',
];

final mobilePattern = RegExp(r'^\+91[6-9]\d{9}$');
final userIdPattern = RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,35}$');
final otpPattern = RegExp(r'^\d{6}$');

bool isMockPhone(String phone) => phone == mockPhone;

/// The fixed test code is off unless the function variable `OTP_MOCK` is `1`.
bool mockOtpEnabled(Map<String, String> env) => (env['OTP_MOCK'] ?? '').trim() == '1';

bool whatsAppReady(Map<String, String> env) {
  if ((env['OTP_PEPPER'] ?? '').trim().length < minPepperLength) return false;
  return _configKeys.every((key) => (env[key] ?? '').trim().isNotEmpty);
}

String pepperFor({
  required String configured,
  required String phone,
  bool mockEnabled = false,
}) {
  final value = configured.trim();
  final mock = mockEnabled && isMockPhone(phone);
  if (mock) return value.length >= minPepperLength ? value : mockPepper;
  if (value.length >= minPepperLength) return value;
  return '';
}

class SendWindow {
  const SendWindow({
    required this.windowStart,
    required this.sendCount,
    required this.allowed,
  });

  final int windowStart;
  final int sendCount;
  final bool allowed;
}

/// Five sends per phone per hour, and a shared cap across every number.
/// The window survives a deleted challenge.
SendWindow claimSend({
  required int windowStart,
  required int sendCount,
  required int nowMillis,
  int limit = otpSendLimit,
}) {
  final expired = windowStart <= 0 || nowMillis - windowStart >= otpSendWindow.inMilliseconds;
  if (expired) return SendWindow(windowStart: nowMillis, sendCount: 1, allowed: true);
  if (sendCount >= limit) {
    return SendWindow(windowStart: windowStart, sendCount: sendCount, allowed: false);
  }
  return SendWindow(windowStart: windowStart, sendCount: sendCount + 1, allowed: true);
}

class AttemptClaim {
  const AttemptClaim({required this.attempts, required this.blocked});

  final int attempts;
  final bool blocked;
}

AttemptClaim nextAttempt({required int attempts}) {
  if (attempts >= otpMaxAttempts) return AttemptClaim(attempts: attempts, blocked: true);
  return AttemptClaim(attempts: attempts + 1, blocked: false);
}

String sendLimitId(String phone) => sha256.convert(utf8.encode('otp:$phone')).toString().substring(0, 20);

String codeHash({
  required String pepper,
  required String userId,
  required String code,
}) {
  final mac = Hmac(sha256, utf8.encode(pepper));
  return mac.convert(utf8.encode('$userId:$code')).toString();
}

bool sameHash(String left, String right) {
  final a = utf8.encode(left);
  final b = utf8.encode(right);
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

String? cooldownError({required int sentAtMillis, required int nowMillis}) {
  if (sentAtMillis <= 0) return null;
  if (nowMillis - sentAtMillis < otpCooldown.inMilliseconds) return otpWait;
  return null;
}

bool isExpired({required int expiresAtMillis, required int nowMillis}) {
  return expiresAtMillis <= nowMillis;
}

int epochMillis(Object? value) => int.tryParse('${value ?? ''}') ?? 0;

int readAttempts(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? 0;
}

String whatsAppTemplate(Map<String, String> env) {
  final configured = (env['MSG91_WHATSAPP_TEMPLATE'] ?? '').trim();
  return configured.isEmpty ? whatsAppTemplateName : configured;
}

/// MSG91 OTP widget `loomWhatsAppOTP`: 6 digits, 30-second resend, 15 minutes.
Map<String, Object?> msg91OtpBody({
  required String template,
  required String phone,
  required String code,
}) {
  final digits = phone.startsWith('+') ? phone.substring(1) : phone;
  return {
    'template_id': template,
    'mobile': digits,
    'otp': code,
    'otp_length': 6,
    'otp_expiry': otpLifetime.inMinutes,
  };
}
