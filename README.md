# Bloom

Bloom is a quick shop for vegetables, fruit, and regional flowers. One Flutter codebase runs on Android, iPhone, and in the browser. Customers browse like a quick-commerce app. The store owner updates prices, availability, and order status.

Without Appwrite credentials the app runs on an in-memory catalog, so you can click through the whole shop immediately. Email and phone sign-in accept the code `123456` in that demo. Online pay confirms in a demo dialog and does not charge a bank. Neither shortcut is shown in a release build.

## Run the shop

```bash
flutter run -d chrome
flutter run
```

Debug builds without Appwrite use the in-memory shop. Demo customer, owner, and rider emails, and the demo password, live in `MemoryBackend`. A release build without Appwrite defines does not open that shop.

Delivery is ₹25, and free from ₹199. The service area starts as Malur, pin 563130. The owner can change the city, the fee, and the free-delivery threshold. The live store row keeps its saved city until that is saved again from owner Settings.

The owner can add riders. A live rider gets an email code and signs in with Forgot password, then shares a pin while a delivery is out. Customers can review a delivered order. The map uses OpenStreetMap tiles unless `BLOOMLY_MAP_TILES` points at a host whose terms allow the traffic. The web Content-Security-Policy allows the public OSM host; add another host there if you change the tile URL.

Customers sign in with a 6-digit code emailed by Appwrite. A mobile number still works on WhatsApp or SMS. A password stays available for the store owner and riders, including forgot password. After sign-in, Account can turn on Face ID or fingerprint unlock for the next time the app opens.

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
| `phone-login` | users.read, users.write, rows.read, rows.write | secret `APPWRITE_API_KEY` (same key as seed; dynamic function keys can arrive empty). WhatsApp also needs `OTP_PEPPER` and `MSG91_AUTH_KEY`. The template defaults to `loomWhatsAppOTP` (6 digits, 30-second resend, 15 minutes). Set `MSG91_WHATSAPP_TEMPLATE` only to override it. SMS stays off until `SMS_LOGIN` is `1` and the app’s `smsLoginLive` flag is turned on. |
| `payments` | rows.read, rows.write, users.read, users.write | secret `APPWRITE_API_KEY`, plus `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET`, and `RAZORPAY_WEBHOOK_SECRET`. `BLOOMLY_UPI_ID` and `BLOOMLY_UPI_NAME` are no longer used at checkout. |

`dart run tool/seed.dart` reads those values from the environment or from `.env`. The API key stays out of the app. If the Appwrite defines are absent, Bloom uses the in-memory shop.

Promo loops, Lottie files, and posters are stored in the existing `product-images` bucket. The project plan allows one bucket, and that bucket already lets anyone read a file while only the owner label can create, update, or delete. The app still refuses a promo file over 5 MB.

The promotions collection does not change. A banner stores the file id or view URL, plus an optional poster URL, inside the existing promotions JSON (`mediaKind`, `mediaUrl`, `posterUrl`). Home, category, clip, tile, and splash placements read those fields. The in-memory shop has no bucket: the owner editor offers two sample files under `assets/media/` (a short silent MP4 and a small Lottie). Those loops were generated for this repo and are not third-party assets.

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

Checkout offers cash on delivery, or UPI through Razorpay: GPay, PhonePe, Paytm, or BHIM. The payments function recomputes the bill from the catalog and creates a Razorpay order for that amount. The key secret never leaves the function. Checkout returns only the public key id and the Razorpay order id. A captured payment, from the signed checkout result or from Razorpay’s `payment.captured` webhook, sets the order to Placed and Paid. The customer does not tap “I have paid”, and the store does not confirm the credit. A paid cancel, and a capture that arrives after cancel, asks Razorpay for a refund. `RAZORPAY_WEBHOOK_SECRET` in the local environment is the same value the Razorpay webhook must send. Cash stays unpaid until delivery.

Settlement goes to the bank account on the Razorpay account, not to a personal UPI ID. Test keys (`rzp_test_…`) use Razorpay test mode and do not move real money. Leave `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` empty and the in-memory shop keeps a demo dialog that does not charge a bank.

The webhook URL is the payments function’s public domain in the Appwrite console, not the executions API. Razorpay cannot send the `X-Appwrite-Project` header that the executions API requires. Set `RAZORPAY_WEBHOOK_SECRET` to the secret shown when that webhook is created. Checkout can still verify a payment while the app is open if the webhook secret is not set yet. Unpaid UPI orders cancel after 45 minutes. A capture that arrives after that cancel is recorded and does not place the order again.

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

The web shop is published at https://vinayca1994.github.io/bloomly/ and the public privacy page is https://vinayca1994.github.io/bloomly/privacy.html. Before the stores will accept a build you still need a Play Console app, an Apple Developer team, that privacy URL, a UPI ID for the store, and an SMS account for phone sign-in. The iOS bundle id and Android application id are `com.bloomly.bloomly`.

## Tests

```bash
flutter test
```
