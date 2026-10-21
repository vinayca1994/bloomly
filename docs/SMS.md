# Phone SMS setup (Appwrite + MSG91)

Bloomly calls Appwrite `createPhoneToken`. SMS keys stay in the Appwrite Console only.

Phone auth is already **enabled** on this project. A **mock number** is registered for local testing without MSG91 credits:

| Number | OTP |
| --- | --- |
| `9999999999` (E.164 `+919999999999`) | `123456` |

Use that in the app’s phone sign-in flow until live SMS is configured.

## Live SMS with MSG91 (India)

MSG91 Auth Key: create with **IP Security OFF** (Appwrite Cloud has no fixed outbound IP). Use case e.g. `app otp`, rule Owner.

**DLT (Vi / VILPOWER):** after signup you wait for activation (often ~48h). Example temp id: `VI-1100099902`. When active:

1. Add telemarketer **Walkover Web Solutions (MSG91)** — TM ID `1302157225275643280`
2. Register 6-letter **Sender ID / Header**
3. Register OTP **content template** using `{#var#}` (not promotional)
4. Map Entity + Header + Template in the MSG91 panel
5. Open [Appwrite Cloud](https://cloud.appwrite.io) → Bloomly (FRA) → **Auth** → **Settings** → **SMS** → **MSG91**
6. Paste Auth Key + Sender ID. Never put the Auth Key in `.env`, `dart_defines.json`, or the Flutter app.
7. Test with a real +91 number in Bloomly (Appwrite launch config).

Twilio is supported the same way if you prefer it over MSG91; pick Twilio in the Console instead.

## Verify

- **Mock:** phone `9999999999`, code `123456` → session created.
- **Live:** real +91 number → SMS arrives → code works.
- **Owner (email):** `srichandankrishnaenterprises@gmail.com` / `bloomly123` → `/owner` (no SMS needed).

## Costs

Each live OTP is billed by MSG91. Keep mock numbers for developers; remove them before production if you do not want fixed test OTPs.
