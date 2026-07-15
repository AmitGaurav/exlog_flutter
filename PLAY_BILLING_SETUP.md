# Google Play Billing Setup

External (Play Console / GCP) configuration required before the app's
Upgrade to Premium flow can complete a real purchase. The client
(`lib/features/more/`) and the shared Cloud Functions backend
(`workspace-ios/exlog/functions/src/{androidPublisher,verifyPlayPurchase,playWebhook}.ts`)
are already coded against the exact product IDs below — nothing on the code
side needs to change once these exist in Play Console.

## 1. Create products in Play Console

Play Console → your app → Monetize → Products.

**Subscription** — one product, two base plans:

| Field | Value |
|---|---|
| Product ID | `premium_subscription` |
| Base plan ID | `monthly` |
| Price | ₹49 / month |
| Base plan ID | `yearly` |
| Price | ₹299 / year |

Both base plans must be **Active** (not just saved as draft) for
`queryProductDetails` to return them.

**One-time managed product:**

| Field | Value |
|---|---|
| Product ID | `premium_lifetime` |
| Price | ₹799 (one-time) |

## 2. Enable Real-time developer notifications (RTDN)

Play Console → Monetize setup → Real-time developer notifications.

1. Create a Pub/Sub topic (e.g. `play-rtdn`) in the GCP project `explog-dec02`
   if one doesn't already exist.
2. Point Play Console's RTDN setting at that topic.
3. GCP Console → Pub/Sub → the `play-rtdn` topic → create a **push
   subscription** whose endpoint is the deployed `playServerNotification`
   Cloud Function URL:

   ```
   https://us-central1-explog-dec02.cloudfunctions.net/playServerNotification
   ```

   (Already deployed as of this writing — re-check with `firebase
   functions:list` if it's ever redeployed under a different URL scheme.)

## 3. Grant API access to the Cloud Functions service account

Play Console → Setup → API access.

1. Link the GCP project `explog-dec02` if not already linked.
2. Grant the default Cloud Functions runtime service account
   (`explog-dec02@appspot.gserviceaccount.com`) access with at least
   **View financial data** + **Manage orders and subscriptions**
   permissions. This lets `verifyPlayPurchase` and `playServerNotification`
   call the Play Developer API (`androidpublisher`) via Application Default
   Credentials — no manual service account key file needed.

## 4. Add a license tester

Play Console → Setup → License testing → add the Google account(s) used on
test devices/emulators. Without this, test purchases on a non-published app
build will fail or charge real money depending on track.

## 5. Deploy

`verifyPlayPurchase` and `playServerNotification` are already deployed to
`explog-dec02`. If you change either function later, redeploy with:

```bash
cd /Users/amitgaurav/workspace-ios/exlog/functions
firebase deploy --only functions:verifyPlayPurchase,functions:playServerNotification
```

## Manual test checklist (once 1–4 above are done)

- [ ] Buy Monthly as a license tester → `users/{uid}/subscription/current`
      and root `premiumTier` update to `monthly`/active without app restart
      (Profile page dispatches `UserProfileLoadRequested` on sheet close).
- [ ] Buy Yearly → same, tier `yearly`.
- [ ] Buy Lifetime → same, tier `lifetime`, one-time (no recurring billing).
- [ ] Play Console → Subscriptions → cancel the test subscription → RTDN
      fires → `playServerNotification` re-fetches state → `premiumTier`
      downgrades to free within a few minutes.
- [ ] Refund a test purchase from Play Console → same downgrade path via
      RTDN.
- [ ] "Restore Purchases" on a fresh install with the same tester account
      re-grants premium without a new charge.
