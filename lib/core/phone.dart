/// SMS stays off until the DLT template is approved.
/// Set this to true in the same release that turns SMS sending on.
bool get smsLoginLive => false;

/// Indian mobile numbers stored as E.164, for example +919876543210.
class PhoneNumber {
  static final _mobile = RegExp(r'^[6-9]\d{9}$');

  static String? normalizeIndia(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    if (!_mobile.hasMatch(digits)) return null;
    return '+91$digits';
  }

  static Uri? telUri(String raw) {
    final e164 = normalizeIndia(raw);
    if (e164 == null) return null;
    return Uri(scheme: 'tel', path: e164);
  }

  static Uri? whatsAppUri(String raw, {String text = ''}) {
    final e164 = normalizeIndia(raw);
    if (e164 == null) return null;
    return Uri.https('wa.me', e164.substring(1), {
      if (text.trim().isNotEmpty) 'text': text.trim(),
    });
  }
}
