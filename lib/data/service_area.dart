/// First launch: Malur town, pin 563130.
const launchCity = 'Malur';
const launchPincode = '563130';

String deliveryPin(String storePincode) {
  final pin = storePincode.trim();
  return pin.isEmpty ? launchPincode : pin;
}

String deliveryAreaMessage(String city, {String pincode = ''}) {
  final name = city.trim().isEmpty ? launchCity : city.trim();
  return 'Bloom delivers in $name, ${deliveryPin(pincode)} only.';
}

/// Checkout and order create. City and pin must match the store.
bool inDeliveryArea({
  required String city,
  required String pincode,
  required String storeCity,
  String storePincode = '',
}) {
  return city.trim().toLowerCase() == storeCity.trim().toLowerCase() &&
      pincode.trim() == deliveryPin(storePincode);
}

/// Home banner. A missing pin is not treated as outside the area.
bool outsideDelivery({
  required String city,
  required String pincode,
  required String storeCity,
  String storePincode = '',
}) {
  if (city.trim().isEmpty) return false;
  if (city.trim().toLowerCase() != storeCity.trim().toLowerCase()) return true;
  if (pincode.trim().isEmpty) return false;
  return pincode.trim() != deliveryPin(storePincode);
}
