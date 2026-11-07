# Phone OTP (SMS and WhatsApp)

Customers can ask for a login code on WhatsApp or by SMS. Both paths end in an Appwrite session. The Flutter app never holds an MSG91 key.

SMS uses Appwrite `createPhoneToken`. WhatsApp is sent by the `phone-login` function, which stores only a hash of the code and returns a session secret after the code matches.

Phone auth is already **enabled**. A mock number works for both channels without MSG91 credits only when the `phone-login` function variable `OTP_MOCK` is `1`:

| Number | OTP |
| --- | --- |
| `9999999999` (E.164 `+919999999999`) | `123456` |

Leave `OTP_MOCK` unset on the production function. The mock path does not call MSG91.

## Live SMS with MSG91 (India)

MSG91 Auth Key: create with **IP Security OFF** (Appwrite Cloud has no fixed outbound IP). Use case e.g. `app otp`, rule Owner.

**DLT (Vi / VILPOWER):** after signup you wait for activation (often ~48h). Example temp id: `VI-1100099902`. When active, register a **new** header and template. Do not reuse a rejected Transactional OTP template for app login.

### Why templates get rejected

App / e-commerce **login OTP** is **Service Implicit** on Vi Power. **Transactional** is only for bank OTPs that complete a banking transaction. Promotional wording, missing brand name, more than one variable, or a header that does not match the brand in the body are common reject reasons.

On this Vi Power entity the OTP placeholder is **`{#num#}`** (numeric), not `{#var#}`. That is correct for a 6-digit login code. Appwrite sends **only the digits** into that variable (keep under 30 characters). The fixed text around `{#num#}` must match the approved DLT template exactly.

### 1. Header (Sender ID) on Vi Power

| Field | Value |
| --- | --- |
| Header type | **Others** (not Promotional) |
| Header | `BLOOMY` |
| Length | exactly 6 letters |
| Case | register in **UPPERCASE** and use the same case in MSG91 / Appwrite |

`BLOOMY` is the Bloom brand in six letters. If Vi Power already has a different approved brand name on the Principal Entity, change the brand word in the template below to that exact name, and pick a 6-letter header that still matches it.

### 2. Content template on Vi Power

| Field | Value |
| --- | --- |
| Template name | `Bloom Login OTP` |
| Category | **Service Implicit** |
| Type | Text / English |
| Consent | Implicit (Service Implicit) |

Paste this **exact** body. One `{#num#}` only. No double spaces. Brand name present:

```
{#num#} is your Bloom login OTP. Do not share it with anyone.
```

Fallback if they ask for an expiry line (still Service Implicit, still one `{#num#}`):

```
{#num#} is your Bloom login OTP. Valid for 10 minutes. Do not share it.
```

Do **not** register these for app login:

- Category Transactional
- `{#var#}` when the portal only offers `{#num#}` for OTP
- More than one variable
- Letters or long text stuffed into `{#num#}`
- Words like offer, discount, free, buy, click

### 3. Telemarketer + MSG91 map

1. On Vi Power, add telemarketer **Walkover Web Solutions (MSG91)** — TM ID `1302157225275643280`
2. Link header `BLOOMY` and the approved template to that telemarketer
3. In MSG91 → SMS: create / import Sender ID `BLOOMY` and the same template text
4. In MSG91, map Entity ID + Header + Template. Note the MSG91 **Template ID** (Flow / Template id)
5. Open [Appwrite Cloud](https://cloud.appwrite.io) → Bloom (FRA) → **Auth** → **Settings** → **SMS** → **MSG91**
6. Paste Auth Key, Sender ID `BLOOMY`, and Template ID if the form asks for it. Never put the Auth Key in `.env`, `dart_defines.json`, or the Flutter app.
7. Test with a real +91 number in Bloom (Appwrite launch config). Expected SMS:

   `123456 is your Bloom login OTP. Do not share it with anyone.`

   (digits change; the rest must match the template.)

Twilio is supported the same way if you prefer it over MSG91; pick Twilio in the Console instead.

## WhatsApp with MSG91

The live MSG91 OTP template is `loomWhatsAppOTP`: WhatsApp, 6 digits, a 30-second resend, 15 minutes, Active and Enabled. The app shows WhatsApp only. SMS stays hidden until the DLT template is approved: set the function variable `SMS_LOGIN` to `1` and set `smsLoginLive` to true in `lib/core/phone.dart` in the same release.

1. In MSG91, keep `loomWhatsAppOTP` enabled on the connected WhatsApp number.
2. Run `dart run tool/seed.dart` so the server-only `otp_challenges` table exists.
3. On the `phone-login` function in the Appwrite console, set these variables. Do not put them in `.env`, `dart_defines.json`, or the app:

   - `OTP_PEPPER` — at least 32 random characters, used to hash codes
   - `OTP_MOCK` — set to `1` only on a development function. Leave it unset in production.
   - `MSG91_AUTH_KEY`
   - `MSG91_WHATSAPP_TEMPLATE` — optional. Empty uses `loomWhatsAppOTP`.

4. Deploy `phone-login` (`appwrite push functions`). Its scopes are `users.read`, `users.write`, `rows.read`, and `rows.write`.
5. If the pepper or auth key is missing, the app says WhatsApp is not set up yet.

The function calls MSG91 `POST https://control.msg91.com/api/v5/otp` with that template id, the 6-digit code, and a 15-minute expiry. A resend waits 30 seconds, and five wrong tries invalidate the code.

## Verify

- **Mock, either channel, `OTP_MOCK=1`:** phone `9999999999`, code `123456` → session created.
- **SMS:** real +91 number → SMS arrives → code works.
- **WhatsApp:** real +91 number that has WhatsApp → message arrives → code works. The same number signs into the same Appwrite user as SMS.
- **Owner (email):** the owner account from the seed script → `/owner` (no OTP needed).

## Costs

Each live SMS is billed by MSG91. Each live WhatsApp authentication message is billed by Meta through MSG91. Keep `OTP_MOCK` off in production so the fixed test code is not accepted.
