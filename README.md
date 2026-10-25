# Bloom

Bloom is a quick shop for vegetables, fruit, and regional flowers. One Flutter codebase runs on Android, iPhone, and in the browser. Customers browse like a quick-commerce app. The store owner updates prices, availability, and order status.

Without Appwrite credentials the app runs on an in-memory catalog, so you can click through the whole shop immediately. Phone sign-in accepts the code `123456` in that demo. Until the store saves a UPI ID, online pay confirms in a demo dialog and does not charge a bank. Neither shortcut is shown in a release build.

## Run the shop

```bash
flutter run -d chrome
flutter run
```

Debug builds without Appwrite use the in-memory shop. Demo customer, owner, and rider emails, and the demo password, live in `MemoryBackend`. A release build without Appwrite defines does not open that shop.

Delivery is ₹25, and free from ₹199. The service city starts as Bengaluru. The owner can change the city, the fee, and the free-delivery threshold.

The owner can add riders. A live rider gets an email code and signs in with Forgot password, then shares a pin while a delivery is out. Customers can review a delivered order. The map uses OpenStreetMap tiles unless `BLOOMLY_MAP_TILES` points at a host whose terms allow the traffic. The web Content-Security-Policy allows the public OSM host; add another host there if you change the tile URL.

Customers can also sign in with a mobile number. Email and password stay available, including forgot password. After sign-in, Account can turn on Face ID or fingerprint unlock for the next time the app opens.

## Appwrite

Create a project on [Appwrite Cloud](https://cloud.appwrite.io), then an API key that can manage databases, storage, users, and functions. Copy [.env.example](.env.example). Seed the catalog once:

```bash
export APPWRITE_ENDPOINT="https://<REGION>.cloud.appwrite.io/v1"
export APPWRITE_PROJECT_ID="<PROJECT_ID>"
export APPWRITE_API_KEY="<API_KEY>"
dart run tool/seed.dart
```

Optional: `APPWRITE_OWNER_EMAIL` and `APPWRITE_OWNER_PASSWORD`. Defaults are the demo owner above. Run the seed again after pulling version 1 so the phone, location, and payment columns are added to an existing project. The same command creates the server-only `otp_challenges` table used for WhatsApp codes.

Phone auth is enabled. The sign-in screen can send the code on WhatsApp or by SMS. SMS uses Appwrite `createPhoneToken`. WhatsApp is sent by the `phone-login` function. Step-by-step is in [docs/SMS.md](docs/SMS.md). Until live delivery is configured, use mock number `9999999999` with code `123456` on either channel. The app never holds an MSG91 key.

Deploy the Dart functions with `appwrite push functions --all --force` (see `appwrite.config.json`). Entrypoint is `lib/main.dart`. Free Appwrite plans allow two functions, so account deletion, order writes, and the 15-minute unpaid-UPI sweep are actions on `payments`. Run `dart run tool/seed.dart` again after pulling this version so permissions, indexes, and the `upiTxnRef` / `payment_events` / `otp_limits` columns exist. `APPWRITE_OWNER_PASSWORD` must be at least 12 characters. Change the live owner password in the Appwrite console if it was ever the old demo value, and revoke other owner sessions.

| Id | Scopes | Variables |
| --- | --- | --- |
| `phone-login` | users.read, users.write, rows.read, rows.write | secret `APPWRITE_API_KEY` (same key as seed; dynamic function keys can arrive empty). WhatsApp also needs `OTP_PEPPER`, `MSG91_AUTH_KEY`, `MSG91_WHATSAPP_NUMBER`, `MSG91_WHATSAPP_TEMPLATE`, `MSG91_WHATSAPP_NAMESPACE`, and `MSG91_WHATSAPP_LANGUAGE` on the function. Leave them unset to keep SMS only. |
| `payments` | rows.read, rows.write, users.read, users.write | secret `APPWRITE_API_KEY`, plus `BLOOMLY_UPI_ID`, `BLOOMLY_UPI_NAME` |

`dart run tool/seed.dart` reads those values from the environment or from `.env`. The API key stays out of the app. If the Appwrite defines are absent, Bloom uses the in-memory shop.

Run the app against that project. Pass the UPI ID only if you want it as the default before the owner saves one in Today:

```bash
./scripts/run_appwrite.sh chrome
# or in Cursor / VS Code: launch "Bloom (Appwrite)" / "Bloom (Appwrite · Chrome)"
# which uses --dart-define-from-file=dart_defines.json (never put APPWRITE_API_KEY there)
```


Equivalent manual command:

```bash
flutter run -d chrome \
  --dart-define=APPWRITE_ENDPOINT="$APPWRITE_ENDPOINT" \
  --dart-define=APPWRITE_PROJECT_ID="$APPWRITE_PROJECT_ID" \
  --dart-define=BLOOMLY_UPI_ID="$BLOOMLY_UPI_ID" \
  --dart-define=BLOOMLY_UPI_NAME="$BLOOMLY_UPI_NAME"
```

## Payments

Checkout offers cash on delivery, or UPI through the customer’s own app: BHIM, GPay, PhonePe, or Paytm. There is no payment-gateway fee. The payments function recomputes the bill from the catalog and returns a `upi://pay` link for the store’s UPI ID. The customer pays in their UPI app and taps “I have paid”. The order stays Awaiting payment until the owner taps “Payment received” after the credit shows in the store’s UPI app. A customer cannot mark their own order paid.

Set the UPI ID in the owner console under Today, or with `BLOOMLY_UPI_ID` on the payments function. Use an ID you control, such as `bloom@oksbi`. Leave it blank in the demo and online pay does not contact a bank.

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
flutter build appbundle --obfuscate --split-debug-info=build/debug-info
flutter build web --obfuscate --split-debug-info=build/debug-info \
  --dart-define=APPWRITE_ENDPOINT="$APPWRITE_ENDPOINT" \
  --dart-define=APPWRITE_PROJECT_ID="$APPWRITE_PROJECT_ID" \
  --dart-define=BLOOMLY_UPI_ID="$BLOOMLY_UPI_ID" \
  --dart-define=BLOOMLY_UPI_NAME="$BLOOMLY_UPI_NAME"
flutter build ipa --obfuscate --split-debug-info=build/debug-info \
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
