# Roles, live tracking and tracking UI — 2026-10-25

## 1. Root causes found

**"Workers don't show on some devices."** The database side worked: the
technicians' phones published a position every 60 s (HTTP 200 in the logs)
and sessions were stored. The viewer side was the problem:
- The 📍 tab chose the screen with `user.isAdmin ? control : my-location`.
  Every non-admin phone (role `User`, `Worker`) opened the technician's own
  sharing screen, which never lists anybody.
- RLS on `location_sessions` / `worker_locations` only let tracking *admins*
  read other people's rows, so even with the right screen a non-admin would
  have seen nothing.
- Earlier the worker list was empty for everyone because `tracking_members`
  was empty (fixed on 2026-10-24).

**Oversized / overflowing tracking UI.** Fixed sizes taken from the mockups
(20–26 px text, 58–60 px buttons, 40 px avatars, 28 px gutters, 52 px map
buttons) on every screen size; a three-digit stat overflowed by 5 px on a
320 dp phone (caught by a widget test); landscape stacked the stats, map and
a bottom sheet into ~300 px.

**Role enforcement.** Tickets/assets/repairs were writable by every signed-in
user at the database level; the app only hid the Accounts tab.

## 2. Roles (decided 2026-10-25)

`users.role` values are kept; `Worker` is the Technician role.

| Operation | User | Technician (`Worker`) | Admin |
|---|---|---|---|
| View workers & live locations | ✅ read-only | ❌ (own only) | ✅ |
| Start own location sharing | ❌ | ✅ | ❌ (no own-sharing screen exists) |
| Request / cancel / stop someone's sharing | ❌ | ❌ | ✅ |
| View tickets | ✅ all | ✅ **assigned only** | ✅ |
| Create ticket / asset | ❌ | ❌ | ✅ |
| Change ticket status | ❌ | Awaiting → Completed / Rejected, own tickets | ✅ |
| Damage description, dates, link asset, record repair | ❌ | ✅ own tickets | ✅ |
| Other ticket fields (engineer, priority, branch, comment, amount) | ❌ | ❌ | ✅ |
| Delete tickets / assets | ❌ | ❌ | ✅ |
| Manage accounts / roles | ❌ | ❌ | ✅ |

Adjustments to the requested matrix, documented: admins do not share their
own location (the product has no such screen and nobody would watch it);
technicians don't get the tracking map (they share, they don't watch).

Note: one account has role `User` with position "Technician" and had been
sharing; with these rules it is view-only. Change its role to `Worker` in
Accounts if it should share.

## 3. Enforcement

- **Database** (`20261025185740_role_based_access.sql`, applied):
  `app_role()`, `my_user_id()`, `can_read_ticket()`, `can_work_ticket()`
  (SECURITY DEFINER, `search_path=''`, role read from `public.users`, whose
  role/status only admins can change); new SELECT/INSERT/UPDATE/DELETE
  policies on `tickets`, `assets`, `assets_tickets_details`,
  `assets_repair`; trigger `guard_ticket_update` limits technicians to
  status (Awaiting → Completed/Rejected), dates, damage description and
  attachment; repair-total triggers run as definer so a technician's repair
  still updates totals; tracking: `tracking_is_worker` = role Worker,
  `tracking_can_view` = admins + users, tracking read policies use it.
- **App:** `lib/core/auth/app_permissions.dart` is the single decision point
  (`context.permissions` in widgets). Screens: location tab by role, Add
  Ticket / Add Asset / Delete / status buttons / damage-comment Edit / QR
  link / repair dialog shown only when allowed. Cubits (`TicketsCubit`,
  `AssetsCubit`) refuse disallowed actions before calling the server.
- Error messages from the database are shown as plain text; codes and
  details go to the debug log only.

## 4. Tracking changes

- **Viewers:** Admins and Users get the tracking screen (Users read-only:
  no Request / Pending / Stop). Both start `TrackingControlCubit` at sign-in;
  technicians start `MyTrackingCubit`.
- **Initial fetch → realtime:** unchanged design (load open requests and
  sessions, then subscribe; reconnect re-reads). New: the screen re-reads
  when the app returns from the background.
- **Coordinates:** invalid values (null, NaN, out of range, the 0,0
  placeholder) are never published by the phone nor drawn on the map.
- **Camera:** the overview fits all workers once, then never moves on its
  own (recenter button). The worker and own-location maps follow the
  position until the user pans; recenter turns following back on.
- **Freshness:** a position older than **3 minutes** (`TrackingSession.staleAfter`,
  configurable) is shown as Offline / "Location is out of date"; with ~60 s
  heartbeats this is three missed updates. "Waiting for the first location"
  when sharing is on but no valid fix has arrived.
- Markers are keyed by worker id, so updates move a marker instead of adding one.

## 5. UI changes (tracking screens)

`TrackingSizes` (compact below 380 dp wide or 600 dp tall): 15–16 px titles,
13–14 px body, 44–48 px buttons, 22–26 px avatars, 12–16 px gutters, 42 px
map buttons. Landscape: map and list/details side by side. Text that can be
long ellipsizes; stat numbers and filter chips scale down instead of
overflowing; map controls sit in a SafeArea at the screen's end (RTL-aware).
Loading / empty / error states with Retry.

## 6. Verification (actually run)

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 90/90 passed (new: permission matrix, cubit refusals, read-only tile, 320 dp layout, coordinate validation, invalid-fix publishing) |
| `flutter build apk --debug` | Built |
| `flutter build web` | Built |
| DB dry run (rolled back), 26 identity checks | 26/26 passed |
| DB after apply, spot checks (rolled back) | user 10/10 tickets, technician 8/8 own, technician create denied, user reads tracking |
| iOS build, physical devices | **not run** (Windows; needs your devices) |

## 7. Remaining risks / limits

- **Technicians now see only assigned tickets.** The 3 Technicians currently
  have none; they see an empty list until tickets are assigned to them.
- Background tracking after the app is killed is not possible (see
  `docs/live_location_tracking.md`); Android keeps sharing in the background
  via a foreground-service notification.
- **Web:** browser geolocation needs HTTPS and stops when the tab is
  suspended; sharing is meant for the phone app. Viewing works on web.
- Existing ticket list / home counts for technicians now reflect only their
  tickets (by design).

## 8. Manual test (three accounts)

1. **Admin:** 📍 → all technicians listed; Request → technician accepts → Live
   marker; View → Stop. Tickets: Add Ticket visible; Cancel/Complete on an
   Awaiting ticket.
2. **User:** 📍 → same list and live markers, no Request/Stop buttons;
   tickets visible, no Add Ticket, no status buttons, no Delete, no Edit on
   damage description, no QR button on ticket details.
3. **Technician:** Tickets → only assigned tickets; on an Awaiting ticket:
   Reject / Complete; Edit damage description; QR to add an asset; tap an
   asset to record a repair. 📍 → Start Sharing. No Add Ticket / Add Asset.
4. Rotate to landscape and try a small phone: no overflow stripes.
