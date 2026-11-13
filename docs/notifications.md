# Notifications

Persistent notifications are created **in the database** by triggers, so they
exist even if the person who caused the event closes the app right away. The
app shows them in a list with an unread badge and receives new ones through
Supabase realtime. Push delivery (FCM) is wired as an outbox that a trusted
edge function sends; it needs Firebase credentials before it can run.

## Events and recipients

| Type | When | Recipient |
|---|---|---|
| `ticket.assigned` | ticket created with an engineer, or engineer changed | the (new) engineer |
| `ticket.unassigned` | ticket created without an engineer | all admins |
| `ticket.reassigned` | engineer changed | the previous engineer |
| `ticket.completed` | status → Completed | admins + engineer |
| `ticket.cancelled` | status → Canceled | engineer (operational), admins (info) |
| `ticket.rejected` | status → Rejected | engineer + admins |
| `ticket.reopened` | status → Awaiting | engineer |
| `ticket.priority_changed` | priority changed | engineer |
| `tracking.requested` | admin requests live location | the worker |
| `tracking.accepted` / `declined` / `expired` | worker answers / request expires | the requesting admin |
| `tracking.cancelled` | request withdrawn (admin or ticket change) | the worker |
| `tracking.started` | worker starts sharing on their own | all admins (info) |
| `tracking.arrived` | worker taps "I have arrived" | requesting admin (or all admins) |
| `tracking.ended` | worker stops sharing | requesting admin (info) |
| `tracking.stopped` | admin / ticket change ends sharing | the worker |
| `tracking.unavailable` | no position for 10 min (needs the scheduled job below) | requesting admin |
| `asset.repair_recorded` | a repair is saved | all admins (info) |

Rules applied to every event:
- The person who caused the event is never notified about it.
- Terminated/suspended users get nothing.
- One row per event and recipient (`unique (recipient_id, event_key)`; the key
  includes the transaction id), so a trigger firing twice can't duplicate it.
- GPS positions **never** create notifications, and no notification contains
  coordinates. `data` holds ids only; the app re-reads the target with the
  user's own permissions before opening it.

Not implemented because the workflow doesn't exist in the app/database yet:
technician accept/reject of a *ticket*, "travel started" / "work started"
states, spare-part requests/approvals, low-stock alerts (no inventory
quantities/thresholds), SLA/overdue alerts (no SLA fields). Each needs a
business rule first; the trigger pattern in the migration extends to them.

## In the app

- **Bell with badge** on the home header and the admin tracking header →
  notification list (paged, pull to refresh, mark one / all as read).
- New notifications appear live; a banner with **View** shows for non-tracking
  events (tracking requests already pop up their own dialog).
- Tapping opens: ticket → ticket details; tracking request → the worker's
  location screen; tracking updates → the admin's live map of that worker.
  Missing or no-longer-accessible targets show "This item is no longer
  available".
- The unread count is read from the server on start and after every realtime
  reconnect, and kept in step with reads and arrivals in between.

## Database (`20261024161520_notifications_and_hardening.sql`)

- `notifications`: recipient, type, category (`operational`/`info`), en/ar
  title and body, `data` (ids), entity references, `event_key`, `read_at`,
  `expires_at` (90 days), push outbox columns. RLS: a user reads only their
  own rows; no client writes (read state via `notifications_mark_read(ids)` /
  `notifications_mark_all_read()`).
- `push_tokens`: token → user, platform, locale. Written only via
  `register_push_token` / `unregister_push_token`; a token moves to whoever
  signs in on that device.
- Service-role-only functions for the sender: `push_claim_batch`,
  `push_mark_result`, `push_remove_token`.
- Realtime publication includes `notifications`.

Scheduled jobs (optional, e.g. with `pg_cron`; not created by the migration):
```sql
select cron.schedule('tracking-stale', '*/5 * * * *', 'select public.tracking_notify_stale()');
select cron.schedule('notifications-expire', '0 3 * * *', 'delete from public.notifications where expires_at < now()');
```

## Push delivery (FCM, Firebase project `efs-tickets`)

**App side — implemented 2026-10-28, not yet verified on a device.**
- `main.dart` starts Firebase (`firebase_options.dart`); if that fails the
  app runs with in-app notifications only.
- `FirebasePushService` (`lib/Features/Notifications/data/firebase_push_service.dart`):
  asks permission (Android 13+ / browser), registers the FCM token through
  `register_push_token` (platform `android` / `web`), follows token
  refresh, routes tapped pushes (`onMessageOpenedApp`, `getInitialMessage`;
  on web the `?efs_push=` link), deletes the token on sign-out after the
  cubit unlinks it server-side. Foreground pushes are ignored on purpose:
  the same notification arrives through realtime as an in-app banner.
- Android: channel `efs_notifications` created in `MainActivity.kt`, also
  the manifest default; `POST_NOTIFICATIONS` declared.
- Web: `web/firebase-messaging-sw.js` (Firebase JS 13.1.0, matching
  firebase_core_web). Needs the VAPID key at build time:
  `flutter build web --dart-define=FCM_VAPID_KEY=<key>`; without it web push
  is off. Must be served over HTTPS.
- Uses the registration-token API (`getToken`), deprecated in
  firebase_messaging 17 in favour of FID registration; kept because
  `send-push` sends to `message.token`.

**Server side — `supabase/functions/send-push`, NOT deployed.** FCM HTTP v1
with OAuth2 from a service account (no legacy key). Sends `android`,
`apns` and `webpush` blocks; web click opens `APP_WEB_URL` with the ids.

To turn it on (each step needs your action/approval):
1. Firebase Console → Project settings → Cloud Messaging → Web Push
   certificates → generate a key pair; use the public key as `FCM_VAPID_KEY`.
2. Google Cloud → IAM → service account with *Firebase Cloud Messaging API
   Admin*; create a JSON key. Never commit it.
3. `supabase secrets set FCM_SERVICE_ACCOUNT="$(tr -d '\n' < sa.json)" PUSH_WEBHOOK_SECRET=<random> APP_WEB_URL=https://<web app>`
4. `supabase functions deploy send-push` (`verify_jwt = false`; the function
   checks `x-push-secret`).
5. Dashboard → Database → Webhooks: INSERT on `public.notifications` → POST
   the function URL with header `x-push-secret`.
6. Retries: enable `pg_cron` + `pg_net` and call the same URL every minute.
   Up to 5 attempts within 24 h, `SKIP LOCKED` claims, collapsed on the
   device by `efs-<id>`: at-least-once, not exactly-once. Dead tokens
   (404 / invalid) are removed.
7. Verify: sign in on a phone and in a browser, check a `push_tokens` row
   per device, create a ticket assigned to that user, confirm the push and
   that tapping opens the ticket; check `notifications.push_status`.

Delivery states are distinct: a `notifications` row (created by the
trigger), `push_status = 'sent'` (FCM accepted it for ≥1 device), and
`read_at` (the user opened it). Push failure never rolls back the ticket.

Cost: FCM is free. Supabase Edge Function invocations and realtime messages
count against the plan quotas; check current pricing.
