final _upiId = RegExp(r'^[A-Za-z0-9.\-_]{2,256}@[A-Za-z][A-Za-z0-9.\-]{1,63}$');
final _reference = RegExp(r'^[A-Za-z0-9]{1,35}$');

bool isUpiId(String value) => _upiId.hasMatch(value.trim());

/// Empty is allowed. Invalid text returns null.
String? normalizeUpiReference(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '';
  if (!_reference.hasMatch(value)) return null;
  return value;
}

/// BHIM UPI intent used by GPay, PhonePe, Paytm, and BHIM. Returns null when
/// the store ID is not a UPI address or the amount is not a positive rupee.
String? upiPayUri({
  required String vpa,
  required String name,
  required int amountRupees,
  required String note,
  String transactionRef = '',
}) {
  final id = vpa.trim();
  if (!isUpiId(id) || amountRupees < 1) return null;
  final payee = name.trim().isEmpty ? 'Bloom' : name.trim();
  final trimmed = note.trim();
  final purpose = trimmed.length > 50 ? trimmed.substring(0, 50) : trimmed;
  final ref = transactionRef.trim();
  return Uri(
    scheme: 'upi',
    host: 'pay',
    queryParameters: {
      'pa': id,
      'pn': payee,
      'am': amountRupees.toStringAsFixed(2),
      'cu': 'INR',
      if (purpose.isNotEmpty) 'tn': purpose,
      if (ref.isNotEmpty) 'tr': ref,
    },
  ).toString();
}
