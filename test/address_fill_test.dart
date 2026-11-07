import 'package:bloomly/data/coded_place.dart';
import 'package:bloomly/data/service_area.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a Malur lookup fills city and pin, and keeps a different pin', () {
    final malur = applyLaunchArea(
      const CodedPlace(
        line: '12',
        area: 'Temple Street',
        city: 'Malur',
        pincode: '',
        landmark: 'Bus stand',
      ),
    );
    expect(malur.city, 'Malur');
    expect(malur.pincode, '563130');
    expect(malur.line, '12');
    expect(malur.area, 'Temple Street');

    final otherPin = applyLaunchArea(
      const CodedPlace(area: 'A village', city: 'Malur', pincode: '563160'),
    );
    expect(otherPin.city, 'Malur');
    expect(otherPin.pincode, '563160');

    final byPin = applyLaunchArea(
      const CodedPlace(area: 'Station Road', city: 'Kolar', pincode: '563130'),
    );
    expect(byPin.city, 'Malur');
    expect(byPin.pincode, '563130');

    final away = applyLaunchArea(
      const CodedPlace(area: 'Fort', city: 'Mumbai', pincode: '400001'),
    );
    expect(away.city, 'Mumbai');
    expect(away.pincode, '400001');
  });

  test('a phone result without a road takes the road from Nominatim', () {
    final phone = draftFromPhone(
      name: 'Malur',
      locality: 'Malur',
      subAdministrativeArea: 'Kolar',
      administrativeArea: 'Karnataka',
      postalCode: '563130',
    );
    expect(phone.hasRoad, isFalse);
    final osm = draftFromNominatim({
      'address': {
        'house_number': '18',
        'road': 'Malur-Hosur Road',
        'suburb': 'Malur town',
        'town': 'Malur',
        'postcode': '563130',
        'amenity': 'Bus stand',
      },
    });
    final place = finishGeocode(phone, osm);
    expect(place?.line, '18');
    expect(place?.area, 'Malur-Hosur Road, Malur town');
    expect(place?.city, 'Malur');
    expect(place?.pincode, launchPincode);
    expect(place?.landmark, 'Bus stand');
  });

  test('a phone road is kept when Nominatim is not needed', () {
    final phone = draftFromPhone(
      subThoroughfare: '4',
      thoroughfare: 'Temple Street',
      subLocality: 'Malur town',
      locality: 'Malur',
      postalCode: '563 130',
      name: 'Temple Street',
    );
    expect(phone.hasRoad, isTrue);
    expect(phone.landmark, isEmpty);
    final place = finishGeocode(phone, null);
    expect(place?.line, '4');
    expect(place?.area, 'Temple Street, Malur town');
    expect(place?.pincode, '563130');
  });
}
