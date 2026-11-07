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

class UpiApp {
  const UpiApp({
    required this.name,
    required this.scheme,
    required this.package,
  });

  final String name;
  final String scheme;
  final String package;
}

const upiApps = <UpiApp>[
  UpiApp(
    name: 'GPay',
    scheme: 'tez',
    package: 'com.google.android.apps.nbu.paisa.user',
  ),
  UpiApp(
    name: 'PhonePe',
    scheme: 'phonepe',
    package: 'com.phonepe.app',
  ),
  UpiApp(
    name: 'Paytm',
    scheme: 'paytmmp',
    package: 'net.one97.paytm',
  ),
  UpiApp(
    name: 'BHIM',
    scheme: 'upi',
    package: 'in.org.npci.upiapp',
  ),
];

/// BHIM UPI intent used by GPay, PhonePe, Paytm, and BHIM. Returns null when
/// the store ID is not a UPI address or the amount is not a positive rupee.
String? upiPayUri({
  required String vpa,
  required String name,
  required int amountRupees,
  required String note,
  String transactionRef = '',
}) {
  final query = _upiQuery(
    vpa: vpa,
    name: name,
    amountRupees: amountRupees,
    note: note,
    transactionRef: transactionRef,
  );
  if (query == null) return null;
  return Uri(scheme: 'upi', host: 'pay', queryParameters: query).toString();
}

/// Android opens the chosen package. Other platforms use that app's scheme.
String? upiAppLink({
  required UpiApp app,
  required bool android,
  required String vpa,
  required String name,
  required int amountRupees,
  required String note,
  String transactionRef = '',
}) {
  final query = _upiQuery(
    vpa: vpa,
    name: name,
    amountRupees: amountRupees,
    note: note,
    transactionRef: transactionRef,
  );
  if (query == null) return null;
  final encoded = Uri(queryParameters: query).query;
  if (android) {
    return 'intent://pay?$encoded#Intent;scheme=upi;package=${app.package};end';
  }
  if (app.scheme == 'upi') {
    return Uri(scheme: 'upi', host: 'pay', queryParameters: query).toString();
  }
  final path = app.scheme == 'tez' ? 'upi/pay' : 'pay';
  return '${app.scheme}://$path?$encoded';
}

Map<String, String>? _upiQuery({
  required String vpa,
  required String name,
  required int amountRupees,
  required String note,
  required String transactionRef,
}) {
  final id = vpa.trim();
  if (!isUpiId(id) || amountRupees < 1) return null;
  final payee = name.trim().isEmpty ? 'Bloom' : name.trim();
  final trimmed = note.trim();
  final purpose = trimmed.length > 50 ? trimmed.substring(0, 50) : trimmed;
  final ref = transactionRef.trim();
  return {
    'pa': id,
    'pn': payee,
    'am': amountRupees.toStringAsFixed(2),
    'cu': 'INR',
    if (purpose.isNotEmpty) 'tn': purpose,
    if (ref.isNotEmpty) 'tr': ref,
  };
}
