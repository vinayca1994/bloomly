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
}
