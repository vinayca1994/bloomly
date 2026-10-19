class CodedPlace {
  const CodedPlace({required this.area, required this.city, required this.pincode});

  final String area;
  final String city;
  final String pincode;
}

Future<CodedPlace?> reverseGeocode(double latitude, double longitude) async => null;
