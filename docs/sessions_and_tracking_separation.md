# Single active session and ticket/tracking separation — 2026-10-28

## 1. One active device per account

**Policy:** newest sign-in wins. Signing in on a second device signs the
first one out with the message "This account signed in on another device…".

**Why not just client logout:** Supabase access tokens (JWT, ~1 h) are
checked by signature only; revoking a session in `auth.sessions` stops its
refresh token but not an access token already issued. So the database itself
refuses a replaced session.

**Server** (`supabase/migrations/20261028132627_single_active_session.sql`):

| Piece | Role |
|---|---|
| `public.user_sessions` | Active session per account (user_id, session_id, device_id). Owner can read; no client writes; in realtime. |
| `claim_session(device_id)` | After sign-in. Takes the session id from the **signed JWT** (`session_id` claim), never a parameter; checks it still exists in `auth.sessions`; records it; **revokes all other auth sessions** of the account; unlinks its push tokens. Per-account advisory lock: two simultaneous sign-ins end with exactly one session. |
| `session_is_current()` | False for a signed-in caller whose JWT session isn't the recorded one. True without auth (service role, cron, triggers). |
| Restrictive policy `current_session_only` on every public table | ANDed with existing policies (unchanged): a replaced session reads/writes nothing. |
| `app_role`, `is_admin`, `my_user_id`, `tracking_is_admin/_is_worker/_can_view` | Fail closed for a replaced session, so SECURITY DEFINER RPCs (tracking, tickets) refuse it too. |
| `register_push_token` | Refuses a replaced session (a kicked phone can't re-link pushes). |
| `session_status()` | `current` / `replaced` / `unclaimed` for app start and resume. |

**App:** `SessionGuard` (`lib/core/auth/session_guard.dart`) + `AuthCubit`:
claim before loading the profile (a failed claim never enters the app);
on restore check the status (replaced → signed out with the reason,
unclaimed → claim, offline → continue, the database still enforces);
realtime on the own `user_sessions` row and a check on every app resume;
then the existing sign-out path stops location sharing, realtime, push and
clears every cubit. Edge functions use `auth.getUser`, which rejects a
revoked session.

**Dry run on the live project (rolled back), all passed:** unclaimed account
unrestricted (older builds keep working); claim → status current, other
sessions revoked, push tokens cleared; revoked device: can't claim (SE001),
reads 0 tickets / 0 users, role null, push-token registration and tracking
RPC refused; a new sign-in replaces the old device, which then reads
nothing but still sees its own session row (to be told); other users can't
read session rows.

**Residual limits:**
- Until an account signs in once with a build that claims, it is not
  restricted (transition for installed older builds).
- A replaced device that is offline keeps its local screens until it
  reconnects; it cannot read or write anything on the server.
- Realtime channels already subscribed may deliver events until the
  device processes the sign-out (seconds).

**Status: applied to the live project 2026-10-28 (approved).** Post-apply smoke test (rolled back) passed; 0 accounts claimed yet.
Nothing changes for an account until it signs in with a build that claims.

## 2. Tickets and live tracking separated

Before: ticket details had a Live location card (Request / View), requests
could carry a ticket, and trigger `tracking_end_for_ticket` cancelled
requests and stopped sharing when a ticket was reassigned or closed.

Now:
- App: card removed (`ticket_tracking_action.dart` deleted); request
  dialog, `TrackingControlCubit.requestLocation`, `TrackingRepo.request`,
  `WorkerTrackingPage`, `TrackingSession` no longer have ticket fields;
  the technician's request card shows no ticket. "I have arrived" now shows
  for admin-requested sessions (was: ticket-bound only).
- Database (`20261028132643_decouple_tracking_from_tickets.sql`): trigger
  dropped; `tracking_request_location` ignores `p_ticket_id` (kept for old
  builds); `tracking_respond_request` has no ticket check. Non-destructive:
  `location_requests.ticket_id` stays (0 rows used it).
- Dry run (rolled back), all passed: engineer and technician can't request;
  an old-build request with a ticket id is stored without it; one
  notification per request, repeat returns the same request without a
  second notification; another technician can't answer it; accept → active;
  reassigning and then closing the ticket leaves sharing active.

**Status: applied to the live project 2026-10-28 (approved).** Smoke test: closing a ticket leaves sharing active.

## 3. Location-request notifications

Existing trigger creates `tracking.requested` for the technician (one row
per request: `event_key = tracking.requested:<id>`), bilingual, ids only.
Push goes through `send-push` (not deployed yet, see `notifications.md`).
Changed: tapping it re-reads the request; if it expired or was withdrawn
the app says so instead of showing an empty screen; repeated taps don't
stack the screen; only technicians open it; tracking updates open the live
view for admins **and engineers** (read-only), which were wrongly refused.
