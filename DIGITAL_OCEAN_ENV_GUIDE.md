# Digital Ocean ops guide — wave 3.2 / 3.3 deploy

> **Audience:** the engineer rolling the API onto the existing Digital Ocean droplet.
> **Companion docs:** [AUTH_SECURITY_GUIDE.md](AUTH_SECURITY_GUIDE.md), [DEV_CROSSCHECK_GUIDE.md](DEV_CROSSCHECK_GUIDE.md).
> **Scope:** new env vars to add, MSG91 template change, MongoDB Settings doc tweak, Redis sanity, post-deploy smoke test.

This guide assumes the standard Sushruta deployment shape: Node.js API on a Digital Ocean droplet behind nginx, MongoDB + Redis (either local or managed), and the Flutter app shipping through Play Store + App Store. Adjust paths if your shop uses a different layout.

---

## 1. Environment variables to add

Add these to `/etc/sushruta-api/.env` (or wherever your `dotenv` reads from on the droplet) **before** restarting the API.

| Var | Purpose | Example value |
|---|---|---|
| `SMS_RETRIEVER_HASH_ANDROID` | 11-character hash from the Android Play build. Auto-appended to MSG91 OTP API calls so Android SMS Retriever can autofill. | `aBcDeFgHiJk` |

Get the hash:

1. Have your Flutter dev run the app in **release / Play-Store-signed mode** on a connected device.
2. From a Profile → Developer screen (or a quick debug print), call `OtpAutofillService().getAppSignature()` — it returns the 11-char hash.
3. Paste into `SMS_RETRIEVER_HASH_ANDROID`.

⚠️ The debug build's hash is **different** from the Play Store hash. Until production is signed with the upload key from Play Console, autofill won't fire on user installs. Use Google Play's "App signing" certificate fingerprint in production.

### How to set on Digital Ocean

```bash
# SSH into the droplet
ssh root@<droplet-ip>

# Edit the env file
nano /etc/sushruta-api/.env
# (or wherever — depends on your setup)

# Append:
SMS_RETRIEVER_HASH_ANDROID=aBcDeFgHiJk

# Save + restart the API
sudo systemctl restart sushruta-api
# OR if PM2:
pm2 restart sushruta-api --update-env
```

Verify with:

```bash
curl -X POST https://api.sushrutalgs.in/api/user/sendOtpMail \
  -H 'Content-Type: application/json' \
  -d '{"phone":"9999999999"}' \
  -i
# Then check the SMS body received on the test number — last line
# should be the 11-char hash on its own line.
```

---

## 2. MSG91 template change (required for Android autofill)

In the MSG91 dashboard:

1. Sign in → **Templates** → find the OTP template referenced by `MsgTemplateId`.
2. Edit the template body. Add **two newlines + `##APP_HASH##`** at the very end:

```
Your Sushruta verification code is ##otp##. Do not share with anyone.

##APP_HASH##
```

3. Save → submit for re-approval (DLT in India typically takes 30 min – 24 h).
4. Once approved, the OTP API call we make from the backend (with `&APP_HASH=<hash>`) will substitute the hash into the SMS body.

⚠️ If you skip this step, the API calls still work — but the SMS body won't contain the hash, and Android SMS Retriever won't fire autofill. iOS autofill works either way.

### Test in MSG91 sandbox

MSG91 has a "Send test SMS" button per template. Send to a tablet/phone that has the production app installed. Open the app, log in, request OTP — the SMS should arrive with the hash on the last line + iOS / Android both autofill the field.

---

## 3. MongoDB Settings updates

The new `Setting.min_supported_version` field controls the mandatory-update gate. You set it ONCE per build retirement.

### Initial (no gate)

After deploying the wave-3.2 backend, no gate is active by default — `min_supported_version` defaults to `''` (empty string = no minimum). Existing app builds keep working.

### When you retire a build

```js
// Connect to Mongo via mongosh / Studio 3T / Compass
use sushruta_lms

db.settings.updateOne(
  { deleted_at: null },
  { $set: {
      min_supported_version: "12.2.0",
      update_force_message: "This version is no longer supported. Please update to continue using Sushruta.",
      update_optional_message: "A new version is available with bug fixes and performance improvements."
    }
  }
)
```

After this update + a Redis cache flush (`redis-cli FLUSHDB` or just wait 5 min for the `app:settings` TTL to expire), every Flutter client below `12.2.0` will see the full-screen `MandatoryUpdateGate` blocker on next cold-boot.

### When to bump

Bump `min_supported_version` whenever you ship a backend API change that's NOT backwards-compatible with the previous Flutter build. Common triggers:

- Adding a required field to a request body
- Changing a response shape an old build relied on
- Critical security patch the old client missed

⚠️ Always set it ≥ 24 h **after** the new version hits the App Store + Play Store — give Apple's review-then-rollout pipeline time to ship to all users.

---

## 4. Redis sanity check

Two new code paths now lean on Redis:

- **Idempotency middleware** (24 h replay cache, `idem:*` keys)
- **OTP rate-limit** (sliding lockout, `otp:*` keys)

Both **fail open** if Redis is unreachable — the API stays up, but the protections silently disappear. So an undetected Redis outage = your brute-force shield + duplicate-write guard are off.

### Verify Redis is reachable from the API host

```bash
ssh root@<droplet-ip>
redis-cli ping
# → PONG
# (if it errors, check REDIS_URL / REDIS_HOST in .env)

# Confirm namespace usage
redis-cli KEYS 'idem:*' | head -5
redis-cli KEYS 'otp:*' | head -5
# (will be empty initially; populates as users hit the API)
```

### Add a healthcheck endpoint (one-time, recommended)

If your monitoring (UptimeRobot / Better Uptime / Datadog) doesn't already check Redis, add a quick endpoint:

```js
// src/routes/health.route.js
import { redis } from '@/libs/redis.lib';
router.get('/api/health/redis', async (req, res) => {
  try {
    const pong = await redis.ping();
    return res.json({ ok: pong === 'PONG' });
  } catch (e) {
    return res.status(503).json({ ok: false, err: e.message });
  }
});
```

Then point your uptime checker at `https://api.sushrutalgs.in/api/health/redis`. Page yourself if it ever returns non-200.

---

## 5. Sanity-check the wave-3.2 endpoints

After restart, these should all return 2xx (or 401 if no auth) — no 500s:

```bash
# Public version-gate
curl https://api.sushrutalgs.in/api/app-meta/version-gate
# Expected: {status:200, data:{ min_supported_version:"", update_force_message:"", ... }}

# Sessions list (replace TOKEN + DEVICE_ID)
curl https://api.sushrutalgs.in/api/auth/sessions \
  -H "Authorization: $TOKEN" \
  -H "X-Device-Id: $DEVICE_ID"
# Expected: 200 with sessions array

# Hit verify-OTP with a wrong OTP 4 times in a row from the same IP
# 4th call should return 429 with code OTP_LOCKED
for i in 1 2 3 4 5; do
  curl -X POST https://api.sushrutalgs.in/api/user/verifyOTP \
    -H "Content-Type: application/json" \
    -d '{"phone":"9999999999","otp":"0000"}' -w "\n%{http_code}\n"
done
```

---

## 6. nginx / reverse-proxy notes

The new `X-Device-Id` header must reach the Node API. If your nginx config strips unknown headers (uncommon — most defaults pass everything), confirm:

```nginx
location /api/ {
  proxy_pass http://localhost:8000;
  proxy_set_header Host $host;
  proxy_set_header X-Real-IP $remote_addr;
  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto $scheme;
  # Ensure custom headers pass through (most nginx defaults already
  # do this — adding explicitly for safety):
  proxy_pass_request_headers on;
}
```

If you're behind Cloudflare, no change needed — Cloudflare forwards custom headers by default.

---

## 7. Cache-bust the public version-gate

The `/api/app-meta/version-gate` endpoint reads from the cached `app:settings` Redis entry (5-min TTL). After you update `min_supported_version`, either wait 5 min or:

```bash
redis-cli DEL app:settings
```

Same applies if you change `update_force_message` or `update_optional_message`.

---

## 8. Post-deploy checklist (run once after rollout)

- [ ] `SMS_RETRIEVER_HASH_ANDROID` env var set; `pm2 restart` / `systemctl restart` done
- [ ] MSG91 OTP template updated to include `##APP_HASH##` at the end + DLT-approved
- [ ] Test SMS received on Android device shows the 11-char hash on the last line
- [ ] `redis-cli ping` returns PONG from the API host
- [ ] `/api/app-meta/version-gate` returns 200 with current Settings values
- [ ] Login flow on Android device autofills the OTP via SMS Retriever (no copy-paste)
- [ ] Login flow on iOS shows the OTP in QuickType bar above the keyboard
- [ ] `/api/auth/sessions` returns the current device after login
- [ ] Logging in from a 2nd phone evicts the first (LIFO) — first device 401s on next call
- [ ] Wrong OTP 5 times triggers 429 with `code: OTP_LOCKED`
- [ ] Setting `min_supported_version` to a value > current app version surfaces the
      MandatoryUpdateGate blocker on next app cold-boot

---

## 9. Rollback plan

If anything goes sideways, the wave-3.2 changes are **additive** — rollback is just reverting the API commit and restarting:

```bash
cd /var/www/sushruta-api
git checkout <prior-commit>
npm install --production
pm2 restart sushruta-api --update-env
```

The Flutter app continues to work with the older API — the new endpoints are gated behind `mw(['user','admin'])` so unauthenticated probes 401 cleanly. The new schema fields are optional with sensible defaults; old data reads fine.

To roll back a `min_supported_version` set:

```js
db.settings.updateOne(
  { deleted_at: null },
  { $set: { min_supported_version: "" } }
)
```

```bash
redis-cli DEL app:settings
```

Within 5 min every client stops seeing the mandatory-update gate.

---

## 10. Operational runbook for the future

When you ship a new Flutter build:

1. Build + sign the APK / AAB with your **Play Console upload key**.
2. Run `OtpAutofillService().getAppSignature()` in the signed build → grab the 11-char hash.
3. If the hash is the SAME as the previous Play build (no upload-key rotation), skip step 4.
4. **Otherwise:** update `SMS_RETRIEVER_HASH_ANDROID` on the droplet + `pm2 restart`. Otherwise SMS Retriever stops working on Android.
5. Submit to Play Store + App Store. Wait for both to be approved + visible on stores.
6. Wait 24 h for both rollouts to complete.
7. THEN bump `Setting.min_supported_version` to force older builds to update.
8. `redis-cli DEL app:settings` to bust the cache so the gate goes live immediately.

---

End of guide.
