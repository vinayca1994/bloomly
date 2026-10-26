# UI audit — 26 Oct 2026

Running web app, phone 390×844 and desktop 1280, light and dark. No Android emulator is installed in this environment, so the Android pass was not run. Before shots are `before-home-*` and `before-category-*`. After shots are `after-home-*` and `after-category-*`.

## Counts

| Severity | Found | Fixed | Open |
| --- | ---: | ---: | ---: |
| High | 2 | 2 | 0 |
| Medium | 4 | 3 | 1 |
| Low | 6 | 0 | 6 |

## High

| Issue | Where | Status |
| --- | --- | --- |
| Icons painted as Latin letters. The bottom nav OCR'd as "A 88 = Q" above Home, Categories, Orders, Account. Phosphor was built from raw code points, and this Flutter build does not draw that font, so the fallback font showed letters. | Nav, category tabs, toolbars, steppers | Fixed. Every `BloomIcons` glyph is a Material Symbols Rounded `IconData` from the bundled MaterialIcons font. A home widget test asserts the icons use that family. |
| Light mode was still the Basil green palette. The owner asked for Petal Pop in light and Basil and Lime in dark. | Theme | Fixed. Light primary is `#D22B89` on canvas `#F9F8FC`. Dark primary stays `#4FD39A` on `#0C1511`. |

## Medium

| Issue | Where | Status |
| --- | --- | --- |
| Category had text chips only, no sort, and an unknown aisle was a blank "nothing" line. | Category | Fixed. Top tabs carry real icons. Sort covers Featured, lowest price, highest price, and name. A missing aisle explains itself and offers vegetables. An empty filter can be cleared. |
| Profile control was a letter in a circle ("B"). | Home header | Fixed. It is a person icon. The name stays in the semantics label when someone is signed in. |
| Home category row filtered in place and did not open the aisle. | Home | Fixed. Vegetables, fruit, flowers, puja, and gifting open the category route. All and the festival tab still filter the home feed. |
| A `RenderFlex` overflowed by 44px on the right during the first 390-wide load, in light and dark. A second load and a 390×844 widget test did not repeat it. | Home, first web paint | Open. Not reproduced. The phone-width widget test fails the build if Home overflows. |

## Low (open)

- No Android emulator here, so tap targets were not checked on a device.
- The demo catalog is ready immediately, so the splash still leaves when the one-second gate ends.
- Orders status chips on a phone still scroll, so Out can start off the first screen.
- There is no average-delivery figure, store-open switch, COD switch, or staff count. Those are not in the data.
- Puja lists flowers and Gifting lists garlands and bunches.
- The logo is still the text wordmark.

## Flows that worked

Checked in the browser after the fix: search, adding spinach, cash on delivery and UPI on checkout, saved addresses, customer / owner / rider demo sign-in, owner Today, and the rider home. Console on the 1280 light pass was clean. The 390 pass that overflowed once did not overflow on the later load.

## Category layout

Top tabs, not a left rail. At 390px a rail of about 72px leaves each card under 150px, which is where the price row and the ADD control were already clipping. Top tabs keep a full-width two-column grid, with sub-filters and sort stuck above the grid. The rail would match a Zepto category page more closely, and it loses the photo size this catalog needs.

## Contrast

Ratios are WCAG 2.x relative luminance. Body text needs 4.5. All of these pass.

### Light (Petal Pop)

| Pair | Ratio |
| --- | ---: |
| Plum `#1E172E` on canvas `#F9F8FC` | 16.32 |
| Plum `#1E172E` on white | 17.25 |
| Secondary `#665E79` on white | 6.10 |
| Link `#AE1E70` on white | 6.52 |
| White on brand `#D22B89` | 4.72 |
| White on pressed `#AE1E70` | 6.52 |
| `#891557` on `#FEE5EF` | 7.65 |
| White on discount `#2B7724` | 5.57 |
| Success `#2B7724` on `#ECFCEA` | 5.22 |
| Warning `#624B02` on `#FFF6E2` | 7.73 |
| Danger `#AF2F30` on white | 6.42 |

### Dark (Basil and Lime, unchanged)

| Pair | Ratio |
| --- | ---: |
| `#EAF2EC` on canvas `#0C1511` | 16.28 |
| `#EAF2EC` on surface `#15211B` | 14.55 |
| Secondary `#A3B4AA` on surface | 7.64 |
| `#06231A` on brand `#4FD39A` | 8.80 |
| Ink `#0F1F17` on lime `#C8F25A` | 13.27 |
| Danger `#FF8A7E` on surface | 7.26 |
| Success `#5FD58A` on `#0E2A1A` | 8.33 |

Festival cards keep their own ground and ink, so a Diwali night header stays light-on-dark in both themes. The offer strip uses the discount pair above, which passes in both.
