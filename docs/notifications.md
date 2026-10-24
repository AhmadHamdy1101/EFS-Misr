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

## Push delivery (needs Firebase; not active yet)

Server side, `supabase/functions/send-push` (FCM HTTP v1, OAuth2 from a
service account; no legacy server key):
1. Create a Firebase project, add the Android app (`com.example.efs_misr`, or
   your real id) and the iOS app; upload the APNs key in Firebase.
2. Create a service account key with the *Firebase Cloud Messaging API* role.
3. `supabase secrets set FCM_SERVICE_ACCOUNT="$(cat sa.json | tr -d '\n')" PUSH_WEBHOOK_SECRET=<random>`
4. `supabase functions deploy send-push` (config.toml sets `verify_jwt = false`;
   the function checks `x-push-secret` itself).
5. Dashboard → Database → Webhooks: on INSERT into `public.notifications`,
   POST to the function URL with header `x-push-secret: <same value>`.
6. Retries: call the same URL every minute with the header (pg_cron +
   `net.http_post`). Rows are retried up to 5 times within 24 h, claimed with
   `SKIP LOCKED`, and collapsed on the device by `efs-<id>`. Delivery is
   at-least-once, not exactly-once.

App side (the code ships with `DisabledPushService`):
1. `flutter pub add firebase_core firebase_messaging` and `flutterfire configure`.
2. Implement `PushService` (`lib/Features/Notifications/data/push_service.dart`)
   with `FirebaseMessaging`: request permission, `getToken()` +
   `onTokenRefresh` → `onToken(token, Platform.isIOS ? 'ios' : 'android')`,
   `getInitialMessage()` and `onMessageOpenedApp` → `onOpened(message.data)`,
   `deleteToken()` in `stop()`. Create the Android channel `efs_notifications`.
3. Register it in `lib/core/utils/singelton.dart` instead of
   `DisabledPushService`, after `Firebase.initializeApp()` in `main.dart`.
The cubit already registers the token on sign-in, unregisters it before
sign-out, and routes tapped pushes.

Cost: FCM is free. Supabase Edge Function invocations and realtime messages
count against the plan quotas; check current pricing.
