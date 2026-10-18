# Bloomly application requirements

Bloomly is a single-store quick shop for vegetables, fruit, and regional flowers. One Flutter app ships to Android and the web. Appwrite stores accounts, the catalog, and orders. Until a project id is configured, the same catalog runs in memory.

## Customer

Browse without an account. Sign in with email and password to check out.

Bottom navigation: Home, Categories, Orders, Account. Search sits under the address, not in the tab bar. A green cart bar appears on Home, Categories, and Search: `View cart · N items · ₹total`.

- Home shows the delivery address, an ETA chip, a category icon grid, and rows for Fresh today, Regional flowers, and Bestsellers.
- A category uses a left rail of subcategories and a two-column grid. Flowers add region chips: North, South, East, West.
- A product card shows the photo or a fallback tile, the unit, the price, the struck MRP, and a green ADD control. More than one unit opens a size sheet.
- Cart shows line steppers and the bill. Delivery is ₹25 and free at ₹199. Both numbers live on the store record.
- Checkout is cash on delivery. The address city must match the store city.
- Tracking steps are Placed, Packing, Out for delivery, and Delivered. Cancelled is terminal.

## Owner

The console replaces the shop shell. Wide screens use a sidebar. A phone uses a drawer.

- Today: open orders, today's revenue, unavailable products, and store settings.
- Orders: advance status or cancel.
- Catalog: search, filter, availability switch, inline variant price, and add product.

Only a profile with role `owner` can open `/owner`. On Appwrite that role comes from the user label `owner`, which the seed script sets and customers cannot grant themselves.

## Data

Tables: store, categories, products, variants, addresses, orders, order_items, profiles. Product photos go in the `product-images` bucket. The cart stays on the device until checkout. Order tracking listens to Appwrite Realtime when a project is configured, and to the in-memory store otherwise.

## Out of scope

Live rider maps, multiple stores, coupons, online payments, and push notifications.
