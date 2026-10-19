import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'geocode.dart';

class DetectedPlace {
  const DetectedPlace({
    required this.latitude,
    required this.longitude,
    required this.area,
    required this.city,
    required this.pincode,
  });

  final double latitude;
  final double longitude;
  final String area;
  final String city;
  final String pincode;

  bool outside(String storeCity) {
    if (city.trim().isEmpty) return false;
    return city.trim().toLowerCase() != storeCity.trim().toLowerCase();
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'area': area,
    'city': city,
    'pincode': pincode,
  };

  factory DetectedPlace.fromJson(Map<String, dynamic> json) {
    return DetectedPlace(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
    );
  }
}

class PlaceController extends ChangeNotifier {
  static const _key = 'bloomly.place';

  DetectedPlace? place;
  String? error;
  bool requesting = false;
  bool _disposed = false;

  Future<DetectedPlace?> detect({bool announceLookupFailure = false}) async {
    if (requesting) return place;
    requesting = true;
    error = null;
    _notify();
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);
      if (place == null && saved != null) {
        place = DetectedPlace.fromJson(jsonDecode(saved) as Map<String, dynamic>);
        _notify();
      }
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        error = 'Turn on location to fill your address.';
        return place;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        error = 'Location is off. Type the address instead.';
        return place;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      final coded = await reverseGeocode(position.latitude, position.longitude);
      final detected = DetectedPlace(
        latitude: position.latitude,
        longitude: position.longitude,
        area: coded?.area ?? place?.area ?? '',
        city: coded?.city ?? '',
        pincode: coded?.pincode ?? place?.pincode ?? '',
      );
      if (detected.city.isEmpty && place != null && place!.city.isNotEmpty) {
        place = DetectedPlace(
          latitude: position.latitude,
          longitude: position.longitude,
          area: place!.area,
          city: place!.city,
          pincode: place!.pincode,
        );
      } else {
        place = detected;
      }
      if (announceLookupFailure && (place?.city ?? '').isEmpty) {
        error = 'Type the area and city. Location did not include an address.';
      }
      await prefs.setString(_key, jsonEncode(place!.toJson()));
      return place;
    } on MissingPluginException {
      return place;
    } catch (_) {
      if (announceLookupFailure) {
        error = 'Location is unavailable. Type the address instead.';
      }
      return place;
    } finally {
      requesting = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
