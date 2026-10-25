# Bloom application requirements

Bloom is a single-store quick shop for vegetables, fruit, and regional flowers. One Flutter app ships to Android, iPhone, and the web. Appwrite stores accounts, the catalog, and orders. Until a project id is configured, the same catalog runs in memory.

## Customer

Browse without an account. Sign in with an Indian mobile number and a one-time code, or with email and password. Forgot password sends a 6-digit email code. Phone accounts are customers. Only the Appwrite label `owner` opens the store console.

After a real sign-in, Account can turn on Face ID (iPhone) or fingerprint / face unlock (Android). That unlocks the existing session on this device. The browser hides it. The password is not stored for biometrics.

Bottom navigation: Home, Categories, Orders, Account. Search sits under the address, not in the tab bar. A green cart bar appears on Home, Categories, and Search: `View cart · N items · ₹total`.

- Home asks for location while the app is in use, shows the delivery address or the detected area, an ETA chip, a category icon grid, and rows for Fresh today, Regional flowers, and Bestsellers. A city outside the store city says Bloom does not deliver there.
- A category uses a left rail of subcategories and a two-column grid. Flowers add region chips: North, South, East, West.
- A product card shows the photo or a fallback tile, the unit, the price, the struck MRP, and a green ADD control. More than one unit opens a size sheet.
- Cart shows line steppers and the bill. Delivery is ₹25 and free at ₹199. Both numbers live on the store record.
- Addresses can be typed, edited, set as default, and filled from the current location. Optional landmark. The customer still enters the house and street. Latitude and longitude are kept when the detected city matches.
- Checkout offers cash on delivery, or UPI through BHIM, GPay, PhonePe, or Paytm. The payable amount is computed on the server from catalog prices. The app opens a `upi://pay` link for the store UPI ID. The customer can record or update a UTR reference on tracking. The order becomes Placed only after the owner confirms the credit. Unpaid UPI awaiting payment auto-cancels after 45 minutes. Cash orders are Placed immediately and stay unpaid until delivery.
- Tracking steps are Placed, Packing, Out for delivery, and Delivered. Cancelled is terminal. Customers may cancel while status is Placed or Awaiting payment (before packing). Call and WhatsApp buttons use the store phone from Today settings.
- After delivery the customer can leave one review. The owner assigns a rider once the order is packing. The rider shares a pin, and the order shows it on a map. The pin is not proof of arrival.
- A UPI payment that has not been confirmed stays Awaiting payment. The store sees it so they can confirm or cancel it, and it does not count as revenue.
- If catalog load fails at startup, Retry reloads without restarting the app.
- Account can open privacy details and delete the customer account.

## Owner

The console replaces the shop shell. Wide screens use a sidebar. A phone uses a drawer.

- Today: open orders, today's revenue, unavailable products, and store settings (city, fees, UPI, store phone). Awaiting-payment orders are not open and do not count as revenue.
- Orders: advance status or cancel. Awaiting UPI payments can be confirmed or cancelled. They are not packed until the owner marks the payment received.
- Catalog: search, filter, availability switch, inline variant price, and add product.

Only a profile with role `owner` can open `/owner`. On Appwrite that role comes from the user label `owner`, which the seed script sets and customers cannot grant themselves.

## Data

Tables: store, categories, products, variants, addresses, orders, order_items, profiles. Product photos go in the `product-images` bucket. The cart stays on the device until checkout. Order tracking listens to Appwrite Realtime when a project is configured, and to the in-memory store otherwise.

Orders store `paymentMethod` (`cod` or `upi`), `paymentStatus` (`pending`, `submitted`, `paid`, `failed`, `refund_pending`, or `refunded`), the UPI ID in `gatewayOrderId`, the customer’s reference in `gatewayPaymentId`, and the UPI transaction ref in `upiTxnRef`. Cash and UPI orders are created by `payments`, which reprices from the catalog. Customers can read their orders. They cannot create or update them. The store row stores `upiId`, `upiName`, and `storePhone`. Addresses store optional landmark, latitude, and longitude. Profiles store an optional phone and are created by the server with role `customer`. Rider pins and reviews are readable by that customer, that rider, and the owner.

`payment_events` is append-only and has no client permissions. `otp_challenges` and `otp_limits` are server-only.

Functions: `phone-login` sends and checks WhatsApp codes, and `payments` creates orders, confirms UPI, moves status, assigns riders, stores pins, saves reviews, expires unpaid UPI every 15 minutes, and deletes a signed-in customer (`action: deleteAccount`). Free plans allow two functions, so those actions share `payments`. The Appwrite API key stays on the functions. The UPI ID is public.

## Out of scope

Multiple stores, coupons, stock counts, and push notifications. Google Places autofill and FCM order alerts are later backlog items, not required for first go-live. A bank webhook is not part of UPI confirm; the owner still marks the credit after it shows in the store’s UPI app.
