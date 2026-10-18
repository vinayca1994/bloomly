# Bloomly

Bloomly is a quick shop for vegetables, fruit, and regional flowers. One Flutter codebase runs on Android and in the browser. Customers browse like a quick-commerce app. The store owner updates prices, availability, and order status.

Without Appwrite credentials the app runs on an in-memory catalog, so you can click through the whole shop immediately.

## Run the shop

```bash
flutter run -d chrome
flutter run
```

Demo sign-in, password `bloomly123` for both:

- Customer: `customer@bloomly.app` (a Koramangala address is already saved)
- Owner: `owner@bloomly.app` (opens the store console)

Delivery is cash on delivery. The fee is ₹25, and free from ₹199. The service city starts as Bengaluru. The owner can change the city, the fee, and the free-delivery threshold.

## Appwrite

Create a project on [Appwrite Cloud](https://cloud.appwrite.io), then an API key that can manage databases, storage, and users. Seed the catalog once:

```bash
export APPWRITE_ENDPOINT="https://<REGION>.cloud.appwrite.io/v1"
export APPWRITE_PROJECT_ID="<PROJECT_ID>"
export APPWRITE_API_KEY="<API_KEY>"
dart run tool/seed.dart
```

Optional: `APPWRITE_OWNER_EMAIL` and `APPWRITE_OWNER_PASSWORD`. Defaults are the demo owner above.

Run the app against that project:

```bash
flutter run -d chrome \
  --dart-define=APPWRITE_ENDPOINT="$APPWRITE_ENDPOINT" \
  --dart-define=APPWRITE_PROJECT_ID="$APPWRITE_PROJECT_ID"
```

The API key stays in the seed script. It is not compiled into the app. If those two defines are absent, Bloomly uses the in-memory shop.

## Tests

```bash
flutter test
```
