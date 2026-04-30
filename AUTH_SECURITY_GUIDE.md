# Auth + Security wave 3.2 — integration guide

> **Companion to:** [DEV_CROSSCHECK_GUIDE.md](DEV_CROSSCHECK_GUIDE.md), [EXAM_INTEGRATION_GUIDE_V2.md](EXAM_INTEGRATION_GUIDE_V2.md)
> **Scope:** multi-device session quota, biometric + PIN lock, jailbreak guard, mandatory-update gate, OTP brute-force shield, in-app updates, onboarding carousel, sessions screen.
> **Status:** Backend live (5 new files). Flutter foundations live (10 new files). Wiring into the existing exam_store-style screens is the dev's next step — recipes below.

---

## 1. What landed (file-by-file)

### Backend (`api-ruchir-optimization`, branch `ruchir-optimization`)

| File | Purpose |
|---|---|
| `src/business/deviceSession.business.js` | classifyDeviceClass + claimSession + listSessions + revokeSession + isSessionValid. Single source of truth for `User.loggedInDevices[]` mutations. |
| `src/routes/deviceSession.route.js` | `GET /api/auth/sessions` · `DELETE /api/auth/sessions/:deviceId` · `POST /api/auth/sessions/logout-others` |
| `src/routes/appMeta.route.js` | `GET /api/app-meta/version-gate` — public endpoint returning `min_supported_version`, `update_force_message`, `update_optional_message`. |
| `src/utils/otpRateLimit.util.js` | Redis-backed brute-force shield. 3 fails/60s → 60s lock; 5 fails/5min → 5min lock. Wired on `/verifyOTP` + `/verifyforgotpasswordOTP`. |
| `src/models/Setting.model.js` (modified) | + `min_supported_version`, `update_force_message`, `update_optional_message` fields. |

### Flutter (`app-update_fixes_merge`, branch `ruchir-new-app-upgrade-ui`)

| File | Purpose |
|---|---|
| `pubspec.yaml` (modified) | + `sms_autofill`, `local_auth`, `flutter_jailbreak_detection`, `in_app_update`, `crypto`. |
| `lib/services/biometric_auth_service.dart` | `local_auth` wrapper — Face ID / Touch ID / fingerprint gate. `isAvailable()`, `isEnabled()`, `setEnabled()`, `authenticate()`, `shouldGate()`. |
| `lib/services/pin_lock_service.dart` | 4–8 digit PIN with SHA-256 + salt in `flutter_secure_storage`. Self-locks for 5 min after 5 wrong attempts; clears + forces re-login after 10. |
| `lib/services/jailbreak_guard.dart` | Root / jailbreak detection. Soft warning banner. Cached per session. |
| `lib/services/session_manager_service.dart` | Talks to `/api/auth/sessions`. `list()`, `revoke(deviceId)`, `logoutOthers()`. |
| `lib/services/app_update_service_v2.dart` | Mandatory-gate compute via `/api/app-meta/version-gate` + Android in-app immediate / flexible update + 24h throttle + downgrade detection + changelog viewer. |
| `lib/modules/widgets/auth_widgets.dart` | `OtpResendCountdown`, `InlineFieldError` (with shake), `AuthSkeleton` shimmer rows. |
| `lib/modules/widgets/onboarding_carousel.dart` | First-launch 3-card swipeable. Persisted via `onboarded_v1` SharedPreferences key. |
| `lib/modules/widgets/mandatory_update_gate.dart` | Full-screen blocker when current < min_supported_version. Includes flexible-update progress bar. |
| `lib/modules/profile/device_sessions_screen.dart` | "Active devices" screen for Profile → Security. Class-icon + relative time + per-row revoke + "Sign out from others". |

(From earlier wave 3.1: `otp_autofill_service.dart`, `app_update_service.dart`, `otp_autofill_field.dart` — still relevant; v2 service builds on v1.)

---

## 2. Multi-device session policy

**Quota:** 1 active session per class (mobile / tablet / desktop / laptop). Total live ≤ 3.

**Behaviour on a new login:**
- Same `device_id` → just refresh `lastLogin`. No quota event.
- Different `device_id` AND class slot is free → claim, total session count increases.
- Different `device_id` AND class slot is full → **revoke the oldest in that class (LIFO)** and claim. Server returns `revokedDeviceId`.

**How the client knows it was revoked:**
- Every authenticated request sends `X-Device-Id`.
- Server's request middleware calls `isSessionValid({ user_id, deviceId })` on each call.
- On `false` (this device was revoked elsewhere) → `401`.
- Flutter's `ApiService` should treat `401` from `/api/auth/me` or any heartbeat as "you were signed out from another device" → route to login + show toast.

**Wiring in the existing login flow** (`auth.business.js`):

```js
import DeviceSessionBiz from '@/business/deviceSession.business';

// After password / OTP verifies pass:
const claim = await DeviceSessionBiz.claimSession({
  user_id: user._id,
  deviceType: body.deviceType,    // 'iosMobile' | 'androidTablet' | 'macOS' | etc.
  deviceId: body.deviceId,
  deviceName: body.deviceName,
});
// claim.revokedDeviceId → optional, surface to client so app can toast
//   "Signed out from your tablet"
```

The legacy code that wrote directly to `user.loggedInDevices` should be removed in favour of `claimSession`.

---

## 3. Auth lock layering

The student opens the app cold. We flow through three gates:

```
Cold boot
  │
  ├── App version < min_supported_version?
  │       └── YES → MandatoryUpdateGate (blocking)
  │
  ├── Biometric enabled + hardware available?
  │       ├── YES → prompt Face ID / Touch ID
  │       │         └── pass → enter app
  │       │         └── fail → fall back to PIN
  │       └── NO  → skip
  │
  ├── PIN set?
  │       ├── YES → 4-digit PIN screen
  │       │         └── pass → enter app
  │       │         └── 5 wrong → 5-min lock
  │       │         └── 10 wrong → clear PIN, force OTP login
  │       └── NO  → enter app
```

**Recommended root wiring** (in `lib/app/app.dart` or wherever MaterialApp is built):

```dart
return MaterialApp(
  // ...
  builder: (context, child) {
    return MandatoryUpdateGate(child: child ?? const SizedBox());
  },
  // ...
);
```

After login (in the success branch of `_login()` in `login_with_phone_screen.dart`):

```dart
final bio = BiometricAuthService();
if (await bio.isAvailable() && !await bio.isEnabled()) {
  final wantsBio = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Use Face ID next time?'),
      content: const Text('Quick unlock without retyping your password.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enable')),
      ],
    ),
  );
  if (wantsBio == true) await bio.setEnabled(true);
}
```

On boot (after splash, before pushing to dashboard):

```dart
final bio = BiometricAuthService();
if (await bio.shouldGate()) {
  final ok = await bio.authenticate(reason: 'Unlock Sushruta');
  if (!ok && await PinLockService().isSet()) {
    // Show your PIN entry screen — calls PinLockService().verify(pin)
  }
  if (!ok) {
    Navigator.pushReplacementNamed(context, Routes.login);
    return;
  }
}
```

---

## 4. Mandatory update gate

**Backend admin step:** set `Setting.min_supported_version` (e.g. `"12.2.0"`) before retiring older builds. `update_force_message` overrides the default copy.

**Flutter check:**

```dart
final status = await AppUpdateServiceV2().check();
status.versionLabel;       // "v12.1.1 → v12.2.0"
status.mandatory;          // true → render MandatoryUpdateGate
status.updateAvailable;    // true → soft banner on home
```

The `MandatoryUpdateGate` widget wraps your child and short-circuits when `mandatory == true`. It calls `startUpdate(immediate: true)`:
- **Android:** Google Play in-app immediate update — APK downloads in-app and installs without leaving the app.
- **iOS:** opens the App Store listing (Apple doesn't allow forced installs).

**Throttle:** silent `check()` runs at most once per 24h (controlled via SharedPreferences key `app_last_update_check_at`). Manual `forceCheck()` always refetches.

**Changelog sheet on first launch of new version:**

```dart
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  AppUpdateServiceV2().showChangelogIfFreshInstall(context);
}
```

Compares installed version vs `app_last_seen_version` in SharedPreferences. Skipped on first install (no upgrade context).

**Pre-release banner:**

```dart
if (await AppUpdateServiceV2().isPreRelease()) {
  // current > store — sideload / staged rollout
  // Show "Pre-release vX.Y.Z-beta" badge in settings
}
```

---

## 5. OTP brute-force shield (server-side)

Wired automatically on `/api/user/verifyOTP` and `/api/user/verifyforgotpasswordOTP`. Client sees:

```json
{
  "status": 429,
  "code": "OTP_LOCKED",
  "message": "Too many wrong attempts. Try again in 47s.",
  "retry_after_s": 47
}
```

**Recommended client response:** disable the verify button + show a countdown chip via `OtpResendCountdown(seconds: retry_after_s, onResend: ...)`.

---

## 6. SMS autofill — backend changes required

For Android SMS Retriever to fire autofill, every OTP SMS body **must end with the 11-char app hash** returned by `OtpAutofillService().getAppSignature()` on the running app. Pattern:

```
<#> Your Sushruta verification code is 482917.

abc123XYZ45
```

**Action for backend dev:**
1. Add a config key `SMS_RETRIEVER_HASH_ANDROID` to env / settings.
2. Concatenate it to the bottom of every OTP SMS body sent via Twilio / MSG91 / whatever.
3. The Flutter app surfaces the hash via Profile → Developer settings → "Show app hash" — a 1-click copy for backend testing.

iOS uses no hash; `AutofillHints.oneTimeCode` works automatically when the SMS contains a number that looks like an OTP.

---

## 7. Sessions screen integration

Add a route + entry point in Profile:

```dart
// lib/app/routes.dart
static const String deviceSessions = "deviceSessions";

case deviceSessions:
  return MaterialPageRoute(
    builder: (_) => const DeviceSessionsScreen(),
  );
```

In `dashboard/profile_screen.dart`, add a tile under "Security":

```dart
ListTile(
  leading: const Icon(Icons.devices_rounded),
  title: const Text('Active devices'),
  subtitle: const Text('Manage where you're signed in'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => Navigator.pushNamed(context, Routes.deviceSessions),
),
```

---

## 8. Onboarding carousel

Show on first launch from the splash flow:

```dart
// In MainSplashScreen.checkLoggedIn(), if NOT signed in:
WidgetsBinding.instance.addPostFrameCallback((_) {
  OnboardingCarousel.showIfFirstRun(context);
});
```

Persisted via `SharedPreferences['onboarded_v1']`. Bump the key (e.g. `onboarded_v2`) on next major release to re-show.

---

## 9. Tech-debt cleanup queued for next sprint

| Item | Why |
|---|---|
| Replace `OTPTextField` with `OtpAutofillField` in 5 screens (`verify_otp.dart`, `verify_otp_mail.dart`, `verify_change_mobile_otp.dart`, `signup_with_phone_screen.dart`, etc.) | Closes the SMS-autofill loop end-to-end |
| Tag Crashlytics with `setCustomKey('login_step', ...)` in every catch branch of `_login()` | Spot operator-specific OTP delivery failures |
| Migrate auth screens off `Dimensions.PADDING_SIZE_*` to `AppTokens.s*` | Removes parallel design-language drift |
| Retire `flutter_upgrade_version` OR `upgrader` (we use the former in `AppUpdateService`) | Drop one dep |
| Wire login-success → BiometricAuthService prompt | Activates biometric opt-in path |
| Wire boot-time PIN screen | Currently the service exists but nothing calls `verify()` |

These are intentionally scoped out of this drop because each touches existing screens and needs runtime testing — they'll land one PR per concern in the next sprint.

---

## 10. Backend admin todos

1. **Wire `claimSession` into existing login flow.** The current `auth.business.js` writes to `loggedInDevices` directly in 4–5 places. Each should be replaced with one `await DeviceSessionBiz.claimSession({...})` call so the quota policy + LIFO eviction is enforced consistently.
2. **Set `min_supported_version`** in the Settings doc when retiring builds. Empty string = no gate.
3. **Add session-validity middleware** to the global mw chain so revoked device JWTs 401 cleanly. Pseudo:
   ```js
   if (req.user) {
     const ok = await DeviceSessionBiz.isSessionValid({
       user_id: req.user.id,
       deviceId: req.headers['x-device-id'],
     });
     if (!ok) return unauthorized(res);
   }
   ```
4. **Append `SMS_RETRIEVER_HASH_ANDROID` to every OTP SMS template.**
5. **Confirm Redis is reachable** from `otpRateLimit.util.js` — middleware fails open if Redis is down (no rate limit), so an undetected outage = the brute-force shield is effectively off.

---

End of guide.
