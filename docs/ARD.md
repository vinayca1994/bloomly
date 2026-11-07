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
- Checkout offers cash on delivery, or UPI through Razorpay (GPay, PhonePe, Paytm, or BHIM). The payable amount is computed on the server from catalog prices. Razorpay checkout opens the UPI app and returns a signed result. The order becomes Placed and Paid when that result, or the `payment.captured` webhook, is verified. Unpaid UPI awaiting payment auto-cancels after 45 minutes. Cash orders are Placed immediately and stay unpaid until delivery.
- Tracking steps are Placed, Packing, Out for delivery, and Delivered. Cancelled is terminal. Customers may cancel while status is Placed or Awaiting payment (before packing). Call and WhatsApp buttons use the store phone from Today settings.
- After delivery the customer can leave one review. The owner assigns a rider once the order is packing. The rider shares a pin, and the order shows it on a map. The pin is not proof of arrival.
- A UPI payment that has not been captured stays Awaiting payment. It does not count as revenue. The store can cancel it. The store cannot mark it paid from a typed reference. A captured payment is already Placed and Paid, so the store packs it and assigns a rider. Cancelling a paid UPI order asks Razorpay for a refund. A capture that arrives after cancel is refunded the same way. An account with a paid or refund-pending UPI order cannot be deleted until that refund is processed.
- If catalog load fails at startup, Retry reloads without restarting the app.
- Account can open privacy details and delete the customer account.

## Owner

The console replaces the shop shell. Wide screens use a sidebar. A phone uses a drawer.

- Today: open orders, today's revenue, unavailable products, and store settings (city, fees, store phone). A captured UPI order is open as soon as it is paid. An unpaid checkout does not count as revenue.
- Orders: advance status or cancel. New shows Placed orders, including UPI that Razorpay has captured. Awaiting payment is only an unpaid checkout.
- Catalog: search, filter, availability switch, inline variant price, and add product.

Only a profile with role `owner` can open `/owner`. On Appwrite that role comes from the user label `owner`, which the seed script sets and customers cannot grant themselves.

## Data

Tables: store, categories, products, variants, addresses, orders, order_items, profiles. Product photos go in the `product-images` bucket. The cart stays on the device until checkout. Order tracking listens to Appwrite Realtime when a project is configured, and to the in-memory store otherwise.

Orders store `paymentMethod` (`cod` or `upi`), `paymentStatus` (`pending`, `submitted`, `paid`, `failed`, `refund_pending`, or `refunded`), the Razorpay order id in `gatewayOrderId`, and the Razorpay payment id in `gatewayPaymentId`. Cash and UPI orders are created by `payments`, which reprices from the catalog. Customers can read their orders. They cannot create or update them. The store row still stores `upiId`, `upiName`, `storePhone`, and the delivery `pincode`. Checkout uses that pin, not a hardcoded one. Checkout does not pay that UPI ID. Addresses store optional landmark, latitude, and longitude. Profiles store an optional phone and are created by the server with role `customer`. Rider pins and reviews are readable by that customer, that rider, and the owner.

`payment_events` is append-only and has no client permissions. `otp_challenges` and `otp_limits` are server-only.

Functions: `phone-login` sends and checks WhatsApp codes, and `payments` creates orders, creates a Razorpay order, verifies the checkout signature, accepts the signed `payment.captured` webhook, moves status, assigns riders, stores pins, saves reviews, expires unpaid UPI every 15 minutes, and deletes a signed-in customer (`action: deleteAccount`). Free plans allow two functions, so those actions share `payments`. The function allows `any` execution so Razorpay can call the webhook. Every other action still requires the Appwrite user id. The Appwrite API key and the Razorpay key secret stay on the function. The Razorpay key id is public.

## Out of scope

Multiple stores, coupons, stock counts, and push notifications. Google Places autofill and FCM order alerts are later backlog items, not required for first go-live. UPI is confirmed by Razorpay’s signed result and webhook, not by the store.
