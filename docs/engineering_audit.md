# EFS engineering audit

Branch `feature/pagination`. Pagination is committed (`a694141`); live
tracking, notifications and both audit passes are **uncommitted** working-tree
changes. Database changes below **are applied** to the live project.

## 1. Live database pass — 2026-10-24

Connected project: **EFS Bank Misr** (`cxjgprvhjrjbmrazvrsa`, Postgres 17.4,
the URL the app ships with). The other project in the org ("EFS Bank Masr")
is inactive and was not touched.

Inspected read-only first: tables, columns/types, constraints, indexes,
policies (public + storage), grants, functions (full definitions), triggers,
realtime publication, buckets, extensions, migration history (empty), row
counts and data-consistency aggregates (no row contents were read or logged),
and the Supabase security/performance advisors.

### Confirmed defects in the live database

| # | Class | Finding | Fix |
|---|---|---|---|
| L1 | Security (critical) | `users`, `tickets`, `assets`, `assets_repair`, `branch`, `positions` had a policy `FOR ALL TO public USING (true)` and `anon` had full table privileges: anyone with the anon key (inside the APK) could read, edit and delete them without signing in. | All policies replaced (signed-in read/write for operational tables, admin-only delete, admin-only writes for lookups, guarded self-update for users); all `anon` table privileges revoked. |
| L2 | Security (critical) | `users.password` held plain-text passwords (4 rows), readable through L1 and streamed by realtime (`users` was in the publication). | Column dropped (approved); `users`/`positions` removed from realtime. |
| L3 | Security (critical) | Tracking functions checked `IF auth.uid() IS NULL OR private.tracking_role(...) <> 'admin'`. For users not in `tracking_members` the role is NULL, the condition NULL, and the RAISE skipped. **Verified live** (rolled back): a non-member created a location request for a worker. | NULL-safe `private.tracking_is_admin/_is_worker`; every function rewritten on top of the existing ones (same names, optional new params). |
| L4 | Bug (high) | `tracking_update_location` called `isfinite(double precision)`, which doesn't exist: **every location update failed**. Found by the dry run. | Removed; range checks already reject NaN/Infinity. |
| L5 | Bug (high) | App called RPC `add_asset_repair`, which doesn't exist live: **saving a repair failed**. | Fixed in the app (no DB change): insert the repair directly; the existing triggers compute totals; totals read back. |
| L6 | Data (high) | Trigger `update_assets_tickets_total` set `tickets.amount` to the total of one asset, not the ticket (1 ticket wrong). | Trigger fixed; that ticket recomputed. |
| L7 | Security | Storage bucket `images`: any signed-in user could update/delete any file. | Writes limited to `<own uid>-*` (the app's naming); reads unchanged. |
| L8 | Bug | Admins couldn't read `tracking_members` (empty worker list) or other admins' requests; admins couldn't stop a session; `location_sessions` not in realtime; duplicate pending requests possible. | Policies widened to tracking admins only; admin stop; realtime added; request returns the existing open one. |
| L9 | Security | Trigger/helper functions with mutable `search_path`; anon could execute `recalc_assets_amount`, `update_single_asset_amount`. | `search_path` fixed, EXECUTE revoked. |
| L10 | Performance | 13 unindexed foreign keys (advisor). | Indexes added. |
| L11 | Data | 5 "duplicate" asset–ticket groups turned out to be 34 orphaned links of deleted tickets (`Tickets_id` NULL), not duplicates. | Unique index on (asset, ticket) added; orphans left (not approved for deletion). |

### Migrations applied to the live project (in this order)

| Remote version | File | Approved |
|---|---|---|
| 20261024161312 | `security_and_performance.sql` | yes |
| 20261024161406 | `live_location_tracking.sql` | yes |
| 20261024161520 | `notifications_and_hardening.sql` | yes |
| 20261024161534 | `drop_users_password.sql` | yes (destructive) |
| 20261024161536 | `unique_asset_ticket_links.sql` | yes (deleted 0 rows) |
| 20261024161639 | `revoke_trigger_function_execute.sql` | follow-up of the above |

Local files were renamed to the remote versions so `supabase db push` sees
them as applied. Rollback reference for the tracking functions:
`docs/live_tracking_previous_functions.sql`.

### Validation

- Full dry run of all migrations + checks in one transaction, rolled back.
- After applying: `supabase/tests/dry_run_checks.sql` run as real identities
  (anon, a non-admin user, a worker, an admin) inside a rolled-back
  transaction — **27/27 passed**: anon denied on tables/functions; bypass
  closed; self-promotion blocked; non-admin can't delete; storage writes
  limited to own files; duplicate request returns the same id; worker accept
  → session → publish works; second device `TR002`; stale fix `TR003`;
  others see no tracking rows or notifications; admin sees the live position,
  gets `tracking.accepted`, stops the session (position deleted, worker gets
  `tracking.stopped`); new ticket notifies its engineer; ticket totals match
  repairs; no real duplicate links; `users.password` gone.
- Verified afterwards that no test rows remained.
- Security advisor after: anon table exposure, mutable search_path and anon
  executable functions are gone. Remaining (intentional/out of scope):
  GraphQL visibility to signed-in users (RLS still applies), app RPCs
  executable by `authenticated` (they check roles inside), leaked-password
  protection off, Postgres patch available.

### App changes in this pass

- Repair save no longer depends on the missing RPC
  (`assets_data_source.dart`); linking an asset twice to a ticket is refused.
- Tracking repository calls the live functions
  (`tracking_request_location`, `tracking_respond_request`,
  `tracking_start_session`, `tracking_update_location`,
  `tracking_stop_session`, `tracking_cancel_request`, `tracking_mark_arrived`)
  and maps their SQLSTATEs (`TR001` ended, `TR002` other device, `TR003` stale).

## 2. Earlier pass (code audit, notifications) — summary

| Finding | Fix |
|---|---|
| Terminated/suspended staff could sign in | App refuses + signs out; `update-user` bans/unbans the auth user (edge function **not redeployed**); `is_admin()` ignores them |
| Asset list crashed on an asset without branch | Fallback branch |
| QR scanner fired multiple lookups / stacked pages | One lookup per scan |
| Push token stayed linked after sign-out | Unregistered before sign-out |
| `'Admin'` string repeated | `UserEntity.isAdmin` |
| Notifications | DB triggers → `notifications` table, in-app list/badge/realtime, push outbox + `send-push` edge function (FCM v1, not deployed), see `docs/notifications.md` |

Decision recorded 2026-10-25: ticket write access stays open to all signed-in
staff (no technician/admin split), as in the app today.

## 3. Verification (this pass)

| Check | Result |
|---|---|
| Baseline before | analyze clean, 75/75 tests, 23 files already unformatted (left as is) |
| `dart format` on changed files | done |
| `flutter analyze` | no issues |
| `flutter test` | 75/75 passed |
| `flutter build apk --debug` | passed in the previous pass; Dart changes since are data-layer only |
| Migrations | applied to live; dry run + 27 identity checks passed |
| Edge functions | add-user/update-user/delete-user redeployed; boot + admin-gate smoke test passed; admin end-to-end not run (needs an admin session) |

## 4. Still required / remaining

- **Edge functions** — redeployed from the repo on 2026-10-24 (approved):
  `add-user` v10, `update-user` v3 (adds ban/unban), `delete-user` v2,
  `verify_jwt` on. Checked: each boots and rejects the anon key (401
  "Invalid session"); the profile insert `add-user` performs succeeds against
  the new schema (service role, rolled back). **Not yet tested end to end**:
  creating, editing and disabling an account needs a signed-in admin — do it
  once in the app. `create-user` (live, not in the repo, unused by the app)
  was left as is; consider deleting it. Deploy `send-push` when FCM is set up.
- **Enable tracking**: `tracking_members` is empty — insert the workers
  (see `docs/live_location_tracking.md`), enter branch coordinates.
- **Old app builds** that read tables before sign-in (if any are still
  installed) stop working; current code signs in first.
- Orphaned asset links (34 rows, ticket deleted) — decide whether to delete.
- Enable leaked-password protection (Auth settings); schedule the Postgres upgrade.
- Optional: `pg_cron`/`pg_net` are not enabled, so stale-tracking alerts,
  notification expiry and push retries need them enabled first.
- Push notifications need Firebase (`docs/notifications.md`).
