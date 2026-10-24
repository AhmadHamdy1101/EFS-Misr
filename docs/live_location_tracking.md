# Live location tracking

Admins see where technicians are on a map while they travel to a branch. A
technician's location is shared only after they accept a request or tap
**Start Sharing Location**, and only admins can see it.

## Workflow

**Admin**
1. Open the **location tab** (pin icon) → *Live Tracking Control*. The counts,
   the map and the worker list update live.
2. Tap **Request** on a worker (or **Request** in the *Live location* card on a
   ticket's details, which ties the request to that ticket and its branch).
3. The row shows **Pending** until the technician answers; tap it to cancel.
   Accept / decline / expiry show as a snackbar and in the bell list.
4. **View** opens the worker: live map, destination branch, distance, GPS
   coordinates, last update, accuracy, arrival time, *Call worker*, *Stop
   tracking*.

**Technician**
1. A request pops up as a dialog on any tab (and as a card on the location
   tab) with the ticket, branch, expiry and what is shared with whom.
2. **Accept & share** asks for location permission first, then starts sharing.
   **Decline** shares nothing.
3. While sharing: status, last sent time, connection and GPS warnings, *I have
   arrived* (sets the arrival time; the ticket itself is not changed), and
   **Stop Sharing Location**.
4. A technician can also start sharing without a request.

Sharing ends when the technician stops, an admin cancels, or the ticket is
reassigned / completed / canceled / rejected (database trigger). Losing the
connection does **not** end the session: the admin sees *Offline* / "Location
is out of date" after 3 minutes without an update.

## Setup
1. **Migration — already applied to the live project on 2026-10-24**
   (`20261024161406_live_location_tracking.sql`; listed here for reference).
   It builds on the
   existing tables `tracking_members`, `location_requests`,
   `location_sessions` and `worker_locations`, and only adds:
   - columns `location_requests.ticket_id/end_reason`,
     `location_sessions.device_id/arrived_at/end_reason`,
     `worker_locations.heading/speed`, `branch.latitude/longitude`
   - RLS on the four tracking tables (existing policies on them are replaced)
   - view `tracking_overview` (open requests/sessions with latest position)
   - the existing functions `tracking_request_location`, `tracking_respond_request`,
     `tracking_start_session`, `tracking_update_location`, `tracking_stop_session`, `tracking_cancel_request` (extended, NULL-role bypass fixed) and new `tracking_mark_arrived`
   - realtime on requests, sessions and locations
   - trigger ending tracking when a ticket is reassigned or closed
2. **Enable workers** in `tracking_members` (only enabled workers appear on
   the admin screen and can share). To enable every non-admin user:
   ```sql
   insert into public.tracking_members (user_id, role)
   select userid, 'worker' from public.users
   where userid is not null and coalesce(role, '') <> 'Admin'
   on conflict (user_id) do nothing;
   ```
   App admins (`users.role = 'Admin'`) can always track; rows with role
   `admin` in `tracking_members` also grant it.
3. **Enter branch coordinates** in the `branch` table (Table editor). Without
   them the map shows no destination and no distance; nothing is guessed.
4. `flutter pub get` (adds `flutter_map`, `latlong2`, `geolocator`,
   `url_launcher`). No API keys are needed.
5. Android: permissions are in `AndroidManifest.xml` (fine/coarse location,
   foreground service + `FOREGROUND_SERVICE_LOCATION`, notifications,
   INTERNET). `targetSdk` is 34; a Play Store submission must declare the
   *location* foreground-service type use in the Play Console.
6. iOS: `Info.plist` has the usage strings, `UIBackgroundModes: location`
   and `tel` query scheme. App Store review will ask why background location
   is used; the answer is "live trip tracking started by the user".

## Security model

- Tracking admins: `users.role = 'Admin'` (`is_admin()`) or an enabled
  `tracking_members` row with role `admin` (`tracking_is_admin()`).
  Workers: an enabled `tracking_members` row with role `worker`.
- The tracking tables have **no insert/update/delete policies** for clients
  (only app admins may edit `tracking_members`): clients call the functions
  above, which check the caller and the state in one transaction under a
  per-worker advisory lock.
  - Request: admins only; with a ticket, the technician must be its assigned
    engineer and the ticket open.
  - Accept / decline: only the session's technician, only while pending and
    not expired, and only if the ticket is still theirs.
  - Publish: only the technician, only while active, only from the device that
    accepted (`device_id`), and older fixes than the stored one are ignored.
  - End: the technician or an admin.
- Read (RLS, also applied to realtime and to the `security_invoker` view):
  admins, and the worker for their own rows. Admins see a position only while
  its session is active. Other staff see nothing.
- One pending request and one active session per worker (advisory lock, plus
  unique partial indexes when existing data allows): two admins requesting at
  once get the same request.
- No service-role key in the app.

## Data and cost

`worker_locations` keeps one row per worker (the latest position); there is
no location history, so storage doesn't grow with GPS readings. Position
updates reach admins straight from realtime; only request/session changes
trigger a re-read of `tracking_overview`.

The phone filters movement under 20 m, publishes at most once every 10 s while
moving, and sends a heartbeat once a minute while parked. Rough load for 20
technicians tracked 2 h/day: ≤ 360 writes/hour each while driving, about
15k writes/day (~450k/month). Each write is one realtime message per
subscribed admin.

- **Supabase**: database writes are well within any plan. Realtime messages
  and concurrent connections have plan quotas; check the current Supabase
  pricing page against (writes × admins watching).
- **Map tiles**: OpenStreetMap community servers, free with attribution but
  under a fair-use policy that disallows heavy use. For production, consider a
  paid tile provider (MapTiler, Stadia, Mapbox) and change the URL in
  `tracking_map.dart`.
- **ETA / routing**: not implemented (needs a routing provider). The screen
  shows straight-line distance only.
- **Push notifications**: the app has no push setup (no FCM/APNs). Requests
  arrive in-app through realtime while the app is open. Adding FCM is needed
  to alert a technician whose app is closed.

## Known limitations

- **Background**: Android keeps sharing through a foreground service with a
  visible notification (also with the screen locked). iOS keeps a session
  started in the foreground running in the background, with the blue
  indicator. If the OS or the user **kills the app**, sharing stops; the admin
  sees it go *Offline*. When the technician reopens the app, sharing resumes
  automatically on the same device if permission is still granted.
- Some Android vendors (Xiaomi, Huawei, Oppo) kill foreground services
  aggressively; technicians may need to disable battery optimisation for EFS.
- Pending requests expire after 15 minutes (lazy expiry on the next call; no
  cron job needed).
- Reverse geocoding (street address) is not shown: free geocoders have strict
  usage limits. GPS coordinates are shown instead.

## Manual test checklist (one admin account, one technician account)

Foreground:
- [ ] Admin requests → technician dialog appears on any tab; nothing is on the
      admin map yet.
- [ ] Technician declines → admin sees "declined", row back to *Request*.
- [ ] Request again, wait 15 min, accept → "request expired", nothing shared.
- [ ] Accept with permission denied → error, not accepted. Allow → shares.
- [ ] Admin map marker moves while walking; *Last update* stays "Just now".
- [ ] Two admins request at the same time → one session, both see *Pending*.
- [ ] From a ticket: Request → technician sees the ticket/branch; *I have
      arrived* sets the arrival time; the ticket status is unchanged.
- [ ] Reassign or complete the ticket → sharing stops on the phone, the admin
      row returns to *Request*.
- [ ] Turn off GPS / revoke permission during sharing → technician sees
      *Sharing Paused*, admin sees *Offline* after 3 min; restore → Resume.
- [ ] Airplane mode 5 min → *No connection* on the phone, *Offline* for the
      admin; reconnect → live again without a new request.
- [ ] Technician signs out → sharing stops on the phone.
- [ ] Sign in as a third non-admin user → no access to others' sessions
      (location tab shows only their own).

Background:
- [ ] Android: start sharing, press Home, lock the screen 10 min → the
      notification stays, the admin keeps getting updates.
- [ ] iOS: same, blue indicator visible.
- [ ] Swipe the app away → admin sees *Offline*; reopen → resumes.

Security (SQL editor, as an authenticated non-admin via the API):
- [ ] `select * from location_requests` / `location_sessions` / `worker_locations` return only own rows.
- [ ] `insert/update` on those tables is rejected.
- [ ] `rpc('tracking_request_location', …)` as non-admin is rejected.
- [ ] `rpc('tracking_update_location', …)` for another technician's session or with a
      different `device_id` does not change the row.
