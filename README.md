# Bloomly

Bloomly is a quick shop for vegetables, fruit, and regional flowers. One Flutter codebase runs on Android, iPhone, and in the browser. Customers browse like a quick-commerce app. The store owner updates prices, availability, and order status.

Without Appwrite credentials the app runs on an in-memory catalog, so you can click through the whole shop immediately. Phone sign-in accepts the code `123456` in that demo. Until the store saves a UPI ID, online pay confirms in a demo dialog and does not charge a bank. Neither shortcut is shown in a release build.

## Run the shop

```bash
flutter run -d chrome
flutter run
```

Debug sign-in, password `bloomly123` for both:

- Customer: `customer@bloomly.app` (a Koramangala address is already saved)
- Owner: `owner@bloomly.app` (opens the store console)

Delivery is ₹25, and free from ₹199. The service city starts as Bengaluru. The owner can change the city, the fee, and the free-delivery threshold.

Customers can also sign in with a mobile number. Email and password stay available, including forgot password. After sign-in, Account can turn on Face ID or fingerprint unlock for the next time the app opens.

## Appwrite

Create a project on [Appwrite Cloud](https://cloud.appwrite.io), then an API key that can manage databases, storage, users, and functions. Copy [.env.example](.env.example). Seed the catalog once:

```bash
export APPWRITE_ENDPOINT="https://<REGION>.cloud.appwrite.io/v1"
export APPWRITE_PROJECT_ID="<PROJECT_ID>"
export APPWRITE_API_KEY="<API_KEY>"
dart run tool/seed.dart
```

Optional: `APPWRITE_OWNER_EMAIL` and `APPWRITE_OWNER_PASSWORD`. Defaults are the demo owner above. Run the seed again after pulling version 1 so the phone, location, and payment columns are added to an existing project.

In the Appwrite console, add an SMS provider for phone sign-in. MSG91 is the usual choice for Indian numbers. The app calls `createPhoneToken`; it does not hold an SMS key.

Deploy the three Dart functions in `functions/` with entrypoint `lib/main.dart`. Use these ids:

| Id | Scopes | Variables |
| --- | --- | --- |
| `phone-login` | users.read | the function API key Appwrite injects |
| `payments` | rows.read, rows.write, users.read | `BLOOMLY_UPI_ID`, `BLOOMLY_UPI_NAME` |
| `delete-account` | users.read, users.write, rows.read, rows.write | the function API key |

`dart run tool/seed.dart` reads those values from the environment or from `.env`. The API key stays out of the app. If the Appwrite defines are absent, Bloomly uses the in-memory shop.

Run the app against that project. Pass the UPI ID only if you want it as the default before the owner saves one in Today:

```bash
flutter run -d chrome \
  --dart-define=APPWRITE_ENDPOINT="$APPWRITE_ENDPOINT" \
  --dart-define=APPWRITE_PROJECT_ID="$APPWRITE_PROJECT_ID" \
  --dart-define=BLOOMLY_UPI_ID="$BLOOMLY_UPI_ID" \
  --dart-define=BLOOMLY_UPI_NAME="$BLOOMLY_UPI_NAME"
```

## Payments

Checkout offers cash on delivery, or UPI through the customer’s own app: BHIM, GPay, PhonePe, or Paytm. There is no payment-gateway fee. The payments function recomputes the bill from the catalog and returns a `upi://pay` link for the store’s UPI ID. The customer pays in their UPI app and taps “I have paid”. The order stays Awaiting payment until the owner taps “Payment received” after the credit shows in the store’s UPI app. A customer cannot mark their own order paid.

Set the UPI ID in the owner console under Today, or with `BLOOMLY_UPI_ID` on the payments function. Use an ID you control, such as `bloomly@oksbi`. Leave it blank in the demo and online pay does not contact a bank.

## Release

Android release builds require `android/key.properties` (gitignored):

```
storePassword=<password>
keyPassword=<password>
keyAlias=upload
storeFile=/absolute/path/upload-keystore.jks
```

Create the keystore with `keytool`, then:

```bash
flutter build appbundle
flutter build web \
  --dart-define=APPWRITE_ENDPOINT="$APPWRITE_ENDPOINT" \
  --dart-define=APPWRITE_PROJECT_ID="$APPWRITE_PROJECT_ID" \
  --dart-define=BLOOMLY_UPI_ID="$BLOOMLY_UPI_ID" \
  --dart-define=BLOOMLY_UPI_NAME="$BLOOMLY_UPI_NAME"
flutter build ipa \
  --dart-define=APPWRITE_ENDPOINT="$APPWRITE_ENDPOINT" \
  --dart-define=APPWRITE_PROJECT_ID="$APPWRITE_PROJECT_ID" \
  --dart-define=BLOOMLY_UPI_ID="$BLOOMLY_UPI_ID" \
  --dart-define=BLOOMLY_UPI_NAME="$BLOOMLY_UPI_NAME"
```

Before the stores will accept the build you still need a Play Console app, an Apple Developer team, a public privacy URL (the in-app page is at Account → Privacy), a UPI ID for the store, and an SMS account for phone sign-in. The iOS bundle id and Android application id are `com.bloomly.bloomly`.

## Tests

```bash
flutter test
```
