enum OtpChannel { sms, whatsapp, email }

/// A trimmed, lowercased address with one `@` and a dotted domain.
String? normalizeLoginEmail(String raw) {
  final email = raw.trim().toLowerCase();
  final at = email.indexOf('@');
  if (at < 1 || email.lastIndexOf('@') != at || email.contains(' ')) {
    return null;
  }
  final domain = email.substring(at + 1);
  if (!domain.contains('.') || domain.startsWith('.') || domain.endsWith('.')) {
    return null;
  }
  return email;
}

class PhoneLoginStart {
  const PhoneLoginStart({this.userId, this.error, this.isNew = false});

  final String? userId;
  final String? error;
  final bool isNew;

  bool get ok => error == null && (userId ?? '').isNotEmpty;

  const PhoneLoginStart.failure(this.error) : userId = null, isNew = false;
}

class RecoveryStart {
  const RecoveryStart({this.userId, this.error});

  final String? userId;
  final String? error;

  bool get ok => error == null && (userId ?? '').isNotEmpty;

  const RecoveryStart.failure(this.error) : userId = null;
}
