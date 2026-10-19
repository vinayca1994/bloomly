import 'package:geocoding/geocoding.dart';

class CodedPlace {
  const CodedPlace({required this.area, required this.city, required this.pincode});

  final String area;
  final String city;
  final String pincode;
}

Future<CodedPlace?> reverseGeocode(double latitude, double longitude) async {
  try {
    final marks = await placemarkFromCoordinates(latitude, longitude);
    if (marks.isEmpty) return null;
    final mark = marks.first;
    final area = _first([mark.subLocality, mark.thoroughfare, mark.locality]);
    final city = _first([mark.locality, mark.subAdministrativeArea, mark.administrativeArea]);
    return CodedPlace(area: area, city: city, pincode: (mark.postalCode ?? '').trim());
  } catch (_) {
    return null;
  }
}

String _first(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}
