import 'dart:convert';
import 'dart:io';

import 'package:geocoding/geocoding.dart';

import 'coded_place.dart';

Future<CodedPlace?> reverseGeocode(double latitude, double longitude) async {
  GeocodeDraft? phone;
  try {
    final marks = await placemarkFromCoordinates(latitude, longitude);
    if (marks.isNotEmpty) {
      final mark = marks.first;
      phone = draftFromPhone(
        name: mark.name,
        subThoroughfare: mark.subThoroughfare,
        thoroughfare: mark.thoroughfare,
        subLocality: mark.subLocality,
        locality: mark.locality,
        subAdministrativeArea: mark.subAdministrativeArea,
        administrativeArea: mark.administrativeArea,
        postalCode: mark.postalCode,
      );
    }
  } catch (_) {
    phone = null;
  }
  GeocodeDraft? osm;
  if (phone == null || !phone.hasRoad) {
    osm = await _nominatim(latitude, longitude);
  }
  return finishGeocode(phone, osm);
}

Future<GeocodeDraft?> _nominatim(double latitude, double longitude) async {
  final client = HttpClient();
  try {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'format': 'jsonv2',
      'addressdetails': '1',
      'lat': '$latitude',
      'lon': '$longitude',
    });
    final request = await client.getUrl(uri).timeout(const Duration(seconds: 8));
    request.headers.set(HttpHeaders.userAgentHeader, 'Bloomly');
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      await response.drain<void>();
      return null;
    }
    final body = await response.transform(utf8.decoder).join();
    return draftFromNominatim(jsonDecode(body));
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
