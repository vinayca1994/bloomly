import 'service_area.dart';

class CodedPlace {
  const CodedPlace({
    this.line = '',
    required this.area,
    required this.city,
    required this.pincode,
    this.landmark = '',
  });

  /// House or street number, when the map has one.
  final String line;
  final String area;
  final String city;
  final String pincode;
  final String landmark;
}

/// One geocoder result before the Malur snap.
class GeocodeDraft {
  const GeocodeDraft({
    this.line = '',
    this.area = '',
    this.city = '',
    this.pincode = '',
    this.landmark = '',
    this.hasRoad = false,
  });

  final String line;
  final String area;
  final String city;
  final String pincode;
  final String landmark;
  final bool hasRoad;

  CodedPlace toPlace() => CodedPlace(
    line: line,
    area: area,
    city: city,
    pincode: pincode,
    landmark: landmark,
  );
}

String joinPlaceParts(List<String> parts, {String skip = ''}) {
  final seen = <String>{};
  final skipKey = skip.trim().toLowerCase();
  final out = <String>[];
  for (final part in parts) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    final key = trimmed.toLowerCase();
    if (key == skipKey || !seen.add(key)) continue;
    out.add(trimmed);
  }
  return out.join(', ');
}

String _first(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

String _pin(String? raw) => (raw ?? '').replaceAll(RegExp(r'\s'), '');

String landmarkFrom(String? name, List<String> used) {
  final trimmed = name?.trim() ?? '';
  if (trimmed.isEmpty || trimmed.contains('+')) return '';
  final key = trimmed.toLowerCase();
  for (final part in used) {
    if (part.trim().toLowerCase() == key) return '';
  }
  return trimmed;
}

GeocodeDraft draftFromPhone({
  String? name,
  String? subThoroughfare,
  String? thoroughfare,
  String? subLocality,
  String? locality,
  String? subAdministrativeArea,
  String? administrativeArea,
  String? postalCode,
}) {
  final line = (subThoroughfare ?? '').trim();
  final road = (thoroughfare ?? '').trim();
  final neighbourhood = (subLocality ?? '').trim();
  final city = _first([locality, subAdministrativeArea, administrativeArea]);
  final area = joinPlaceParts([
    road,
    neighbourhood,
    if (road.isEmpty && neighbourhood.isEmpty) locality ?? '',
  ], skip: city);
  return GeocodeDraft(
    line: line,
    area: area,
    city: city,
    pincode: _pin(postalCode),
    landmark: landmarkFrom(name, [line, road, neighbourhood, city, locality ?? '']),
    hasRoad: road.isNotEmpty,
  );
}

GeocodeDraft? draftFromNominatim(Object? json) {
  if (json is! Map) return null;
  final raw = json['address'];
  if (raw is! Map) return null;
  final address = Map<String, dynamic>.from(raw);
  String pick(List<String> keys) {
    for (final key in keys) {
      final value = '${address[key] ?? ''}'.trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  final line = pick(['house_number']);
  final road = pick(['road', 'pedestrian', 'footway', 'residential', 'path']);
  final neighbourhood = pick([
    'neighbourhood',
    'suburb',
    'quarter',
    'hamlet',
    'city_district',
  ]);
  final city = pick(['city', 'town', 'village', 'municipality', 'county']);
  final pin = _pin(pick(['postcode']));
  final landmark = pick(['amenity', 'shop', 'tourism', 'office']);
  final area = joinPlaceParts([road, neighbourhood], skip: city);
  if (line.isEmpty && area.isEmpty && city.isEmpty && pin.isEmpty) return null;
  return GeocodeDraft(
    line: line,
    area: area,
    city: city,
    pincode: pin,
    landmark: landmarkFrom(landmark, [line, road, neighbourhood, city]),
    hasRoad: road.isNotEmpty,
  );
}

/// Phone result wins. Nominatim supplies the road only when the phone has none.
GeocodeDraft? mergeGeocode(GeocodeDraft? phone, GeocodeDraft? osm) {
  if (phone == null) return osm;
  if (osm == null || phone.hasRoad) return phone;
  return GeocodeDraft(
    line: phone.line.isNotEmpty ? phone.line : osm.line,
    area: osm.hasRoad && osm.area.isNotEmpty ? osm.area : phone.area,
    city: phone.city.isNotEmpty ? phone.city : osm.city,
    pincode: phone.pincode.isNotEmpty ? phone.pincode : osm.pincode,
    landmark: phone.landmark.isNotEmpty ? phone.landmark : osm.landmark,
    hasRoad: phone.hasRoad || osm.hasRoad,
  );
}

/// A Malur locality, or pin 563130, becomes city Malur.
/// An empty pin in that area becomes 563130. Any other pin is kept.
CodedPlace applyLaunchArea(CodedPlace place) {
  final city = place.city.trim();
  final pin = place.pincode.trim();
  final inMalur = city.toLowerCase().contains('malur') || pin == launchPincode;
  if (!inMalur) return place;
  return CodedPlace(
    line: place.line,
    area: place.area,
    city: launchCity,
    pincode: pin.isEmpty || pin == launchPincode ? launchPincode : pin,
    landmark: place.landmark,
  );
}

CodedPlace? finishGeocode(GeocodeDraft? phone, GeocodeDraft? osm) {
  final merged = mergeGeocode(phone, osm);
  if (merged == null) return null;
  final place = applyLaunchArea(merged.toPlace());
  if (place.line.isEmpty &&
      place.area.isEmpty &&
      place.city.isEmpty &&
      place.pincode.isEmpty) {
    return null;
  }
  return place;
}
