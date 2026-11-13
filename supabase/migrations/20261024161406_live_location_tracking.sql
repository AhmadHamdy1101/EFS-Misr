-- Live location tracking: extends the tracking system that already exists in
-- the live database (tracking_members, location_requests, location_sessions,
-- worker_locations, private.tracking_role and the tracking_* functions).
--
-- Written against the live schema inspected on 2026-10-24.
--
-- Changes
--   1. SECURITY FIX: the existing functions checked roles with
--        IF auth.uid() IS NULL OR private.tracking_role(...) <> 'admin' THEN RAISE
--      tracking_role() is NULL for users not in tracking_members, so the
--      condition was NULL and the RAISE was skipped: any signed-in user passed
--      the admin/worker checks. All checks are now NULL-safe.
--   2. Admins = enabled tracking_members 'admin' rows OR app admins
--      (users.role = 'Admin', not terminated/suspended).
--   3. Columns: request -> ticket link and end reason; session -> device
--      binding, arrival time, end reason; location -> heading and speed;
--      branch -> coordinates (destination).
--   4. Functions keep their names; new parameters are optional, so existing
--      positional calls still work. Old signatures are dropped and recreated
--      (functions only, no data). Accepting a request now opens the session
--      in the same transaction.
--   5. Admins can read all members/requests/sessions (worker list, pending
--      requests from other admins) and stop active sessions.
--   6. View tracking_overview, realtime for location_sessions, ticket trigger.
--
-- No rows are deleted or rewritten. Rollback: restore the previous function
-- definitions (saved in docs/live_tracking_previous_functions.sql) and
-- policies; the added columns can stay.

begin;

-- ---------------------------------------------------------------------------
-- 1. Columns and indexes
-- ---------------------------------------------------------------------------
alter table public.location_requests
  add column if not exists ticket_id bigint references public.tickets (id) on delete set null,
  add column if not exists end_reason text;

alter table public.location_sessions
  add column if not exists device_id text,
  add column if not exists arrived_at timestamptz,
  add column if not exists end_reason text;

alter table public.worker_locations
  add column if not exists heading double precision,
  add column if not exists speed double precision;

alter table public.branch
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'branch_coordinates_valid') then
    alter table public.branch add constraint branch_coordinates_valid check (
      (latitude is null and longitude is null)
      or (latitude between -90 and 90 and longitude between -180 and 180)
    );
  end if;
end $$;

create index if not exists location_requests_ticket_idx on public.location_requests (ticket_id);
create index if not exists location_requests_admin_idx on public.location_requests (admin_id);
create index if not exists worker_locations_session_idx on public.worker_locations (session_id);
create index if not exists users_userid_idx on public.users (userid);

-- ---------------------------------------------------------------------------
-- 2. Role helpers (NULL-safe)
-- ---------------------------------------------------------------------------
create or replace function private.tracking_is_admin(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user is not null and (
    coalesce(private.tracking_role(p_user) = 'admin', false)
    or exists (
      select 1 from public.users u
      where u.userid = p_user and u.role = 'Admin' and coalesce(u.status, 1) not in (3, 4)
    )
  );
$$;

create or replace function private.tracking_is_worker(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user is not null and coalesce(private.tracking_role(p_user) = 'worker', false);
$$;

revoke all on function private.tracking_is_admin(uuid) from public, anon;
revoke all on function private.tracking_is_worker(uuid) from public, anon;
grant execute on function private.tracking_is_admin(uuid) to authenticated;
grant execute on function private.tracking_is_worker(uuid) to authenticated;
grant usage on schema private to authenticated;

-- ---------------------------------------------------------------------------
-- 3. RLS (read only; writes go through the functions)
-- ---------------------------------------------------------------------------
drop policy if exists tracking_members_self on public.tracking_members;
drop policy if exists tracking_members_read on public.tracking_members;
create policy tracking_members_read on public.tracking_members
  for select to authenticated
  using (user_id = (select auth.uid()) or (select private.tracking_is_admin(auth.uid())));

drop policy if exists tracking_requests_read on public.location_requests;
create policy tracking_requests_read on public.location_requests
  for select to authenticated
  using (worker_id = (select auth.uid()) or (select private.tracking_is_admin(auth.uid())));

drop policy if exists tracking_sessions_read on public.location_sessions;
create policy tracking_sessions_read on public.location_sessions
  for select to authenticated
  using (worker_id = (select auth.uid()) or (select private.tracking_is_admin(auth.uid())));

-- Positions of stopped sessions are deleted by tracking_stop_session; admins
-- additionally only see rows of an active session.
drop policy if exists tracking_locations_read on public.worker_locations;
create policy tracking_locations_read on public.worker_locations
  for select to authenticated
  using (
    worker_id = (select auth.uid())
    or (
      (select private.tracking_is_admin(auth.uid()))
      and exists (
        select 1 from public.location_sessions s
        where s.id = worker_locations.session_id and s.status = 'active'
      )
    )
  );

-- ---------------------------------------------------------------------------
-- 4. Overview: one row per open request or active session (caller's RLS)
-- ---------------------------------------------------------------------------
create or replace view public.tracking_overview
with (security_invoker = true) as
select
  s.id::text as id,
  s.request_id::text as request_id,
  s.id::text as session_id,
  s.worker_id::text as worker_uid,
  wu.id as technician_id,
  au.id as requested_by,
  r.ticket_id,
  t.branch as branch_id,
  'active'::text as status,
  s.end_reason,
  r.created_at as requested_at,
  r.expires_at,
  r.responded_at,
  s.started_at,
  s.arrived_at,
  s.ended_at,
  s.device_id,
  l.latitude,
  l.longitude,
  l.accuracy_meters as accuracy,
  l.heading,
  l.speed,
  l.recorded_at as location_recorded_at,
  l.received_at as last_location_at,
  s.started_at as opened_at
from public.location_sessions s
join public.users wu on wu.userid = s.worker_id
left join public.location_requests r on r.id = s.request_id
left join public.users au on au.userid = r.admin_id
left join public.tickets t on t.id = r.ticket_id
left join public.worker_locations l on l.worker_id = s.worker_id and l.session_id = s.id
where s.status = 'active'
union all
select
  r.id::text, r.id::text, null::text, r.worker_id::text, wu.id, au.id, r.ticket_id, t.branch,
  'pending'::text, null::text, r.created_at, r.expires_at, r.responded_at,
  null::timestamptz, null::timestamptz, null::timestamptz, null::text,
  null::double precision, null::double precision, null::double precision,
  null::double precision, null::double precision, null::timestamptz, null::timestamptz,
  r.created_at
from public.location_requests r
join public.users wu on wu.userid = r.worker_id
left join public.users au on au.userid = r.admin_id
left join public.tickets t on t.id = r.ticket_id
where r.status = 'pending' and r.expires_at > now();

revoke all on public.tracking_overview from anon;
grant select on public.tracking_overview to authenticated;

-- ---------------------------------------------------------------------------
-- 5. Functions (same names, optional new parameters)
-- ---------------------------------------------------------------------------
drop function if exists public.tracking_request_location(uuid);
create or replace function public.tracking_request_location(
  p_worker uuid,
  p_ticket_id bigint default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_id uuid;
  v_worker_user bigint;
  v_ticket public.tickets%rowtype;
begin
  if not private.tracking_is_admin(v_actor) then
    raise exception 'Not authorized';
  end if;
  if not private.tracking_is_worker(p_worker) then
    raise exception 'This worker is not enabled for live tracking.';
  end if;

  if p_ticket_id is not null then
    select id into v_worker_user from public.users where userid = p_worker;
    select * into v_ticket from public.tickets where id = p_ticket_id;
    if not found then
      raise exception 'Ticket not found.';
    end if;
    if v_ticket.engineer is null then
      raise exception 'Assign a technician to this ticket before requesting live location.';
    end if;
    if v_ticket.engineer is distinct from v_worker_user then
      raise exception 'This technician is not assigned to the ticket.';
    end if;
    if coalesce(v_ticket.status, '') in ('Completed', 'Canceled', 'Rejected') then
      raise exception 'This ticket is closed.';
    end if;
  end if;

  -- Serialise requests for the same worker (two admins at once).
  perform 1 from public.tracking_members where user_id = p_worker for update;

  update public.location_requests
  set status = 'expired', responded_at = now(), end_reason = 'Request expired'
  where worker_id = p_worker and status = 'pending' and expires_at <= now();

  -- Already sharing or already asked: return that instead of a duplicate.
  select id into v_id from public.location_sessions
  where worker_id = p_worker and status = 'active';
  if found then
    return v_id;
  end if;
  select id into v_id from public.location_requests
  where worker_id = p_worker and status = 'pending';
  if found then
    return v_id;
  end if;

  insert into public.location_requests (admin_id, worker_id, ticket_id)
  values (v_actor, p_worker, p_ticket_id)
  returning id into v_id;
  return v_id;
end;
$$;

-- Returns 'active' (accepted, session open), 'declined', 'expired' or
-- 'cancelled' (ticket reassigned/closed meanwhile). Repeating the call after
-- it already succeeded returns the same outcome instead of failing.
drop function if exists public.tracking_respond_request(uuid, boolean);
create or replace function public.tracking_respond_request(
  p_request uuid,
  p_accept boolean,
  p_device_id text default null
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.location_requests%rowtype;
  v_ticket public.tickets%rowtype;
  v_me_user bigint;
begin
  if not private.tracking_is_worker(v_actor) then
    raise exception 'Not authorized';
  end if;
  perform 1 from public.tracking_members where user_id = v_actor for update;

  select * into v_row from public.location_requests where id = p_request for update;
  if not found or v_row.worker_id is distinct from v_actor then
    raise exception 'Invalid request';
  end if;
  if v_row.status <> 'pending' then
    return case v_row.status when 'accepted' then 'active' else v_row.status end;
  end if;
  if v_row.expires_at <= now() then
    update public.location_requests
    set status = 'expired', responded_at = now(), end_reason = 'Request expired'
    where id = p_request;
    return 'expired';
  end if;

  if v_row.ticket_id is not null then
    select id into v_me_user from public.users where userid = v_actor;
    select * into v_ticket from public.tickets where id = v_row.ticket_id;
    if v_ticket.engineer is distinct from v_me_user
       or coalesce(v_ticket.status, '') in ('Completed', 'Canceled', 'Rejected') then
      update public.location_requests
      set status = 'cancelled', responded_at = now(), end_reason = 'Ticket reassigned or closed'
      where id = p_request;
      return 'cancelled';
    end if;
  end if;

  if not p_accept then
    update public.location_requests
    set status = 'declined', responded_at = now(), end_reason = 'Declined by worker'
    where id = p_request;
    return 'declined';
  end if;

  update public.location_requests
  set status = 'accepted', responded_at = now()
  where id = p_request;

  if exists (select 1 from public.location_sessions where worker_id = v_actor and status = 'active') then
    -- Already sharing on their own: that session answers the request.
    update public.location_sessions
    set device_id = coalesce(p_device_id, device_id)
    where worker_id = v_actor and status = 'active';
  else
    insert into public.location_sessions (worker_id, request_id, source, device_id)
    values (v_actor, p_request, 'admin_request', p_device_id);
  end if;
  return 'active';
end;
$$;

-- Starts sharing. With p_request: opens the session for an accepted request
-- (idempotent). Without: answers a pending request if there is one, moves an
-- active session to this device, or starts a self-initiated session.
drop function if exists public.tracking_start_session(uuid);
create or replace function public.tracking_start_session(
  p_request uuid default null,
  p_device_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
  v_actor uuid := auth.uid();
  v_row public.location_requests%rowtype;
  v_pending uuid;
begin
  if not private.tracking_is_worker(v_actor) then
    raise exception 'Not authorized';
  end if;
  perform 1 from public.tracking_members where user_id = v_actor for update;

  select id into v_id from public.location_sessions
  where worker_id = v_actor and status = 'active';
  if found then
    update public.location_sessions
    set device_id = coalesce(p_device_id, device_id)
    where id = v_id;
    return v_id;
  end if;

  if p_request is not null then
    select * into v_row from public.location_requests where id = p_request for update;
    if not found or v_row.worker_id is distinct from v_actor or v_row.status <> 'accepted' then
      raise exception 'Request not accepted by this worker';
    end if;
    if v_row.expires_at <= v_row.responded_at then
      raise exception 'Expired approval';
    end if;
    insert into public.location_sessions (worker_id, request_id, source, device_id)
    values (v_actor, p_request, 'admin_request', p_device_id)
    returning id into v_id;
    return v_id;
  end if;

  select id into v_pending from public.location_requests
  where worker_id = v_actor and status = 'pending' and expires_at > now();
  if found then
    perform public.tracking_respond_request(v_pending, true, p_device_id);
    select id into v_id from public.location_sessions
    where worker_id = v_actor and status = 'active';
    return v_id;
  end if;

  insert into public.location_sessions (worker_id, request_id, source, device_id)
  values (v_actor, null, 'worker', p_device_id)
  returning id into v_id;
  return v_id;
end;
$$;

-- Publishes the latest position. Errors use SQLSTATEs the app maps:
--   TR001 no active session, TR002 session bound to another device,
--   TR003 timestamp too old / in the future.
-- Returns false when an older fix than the stored one is ignored.
drop function if exists public.tracking_update_location(uuid, double precision, double precision, double precision, timestamptz);
create or replace function public.tracking_update_location(
  p_session uuid,
  p_lat double precision,
  p_lng double precision,
  p_accuracy double precision default null,
  p_recorded_at timestamptz default null,
  p_heading double precision default null,
  p_speed double precision default null,
  p_device_id text default null
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_time timestamptz := coalesce(p_recorded_at, now());
  v_session public.location_sessions%rowtype;
  v_rows integer;
begin
  if not private.tracking_is_worker(v_actor) then
    raise exception 'Not authorized';
  end if;
  -- The previous version called isfinite(double precision), which doesn't
  -- exist in Postgres, so every location update failed. The range checks
  -- already reject Infinity and NaN (NaN sorts above every number).
  if p_lat is null or p_lng is null
     or not (p_lat between -90 and 90) or not (p_lng between -180 and 180)
     or (p_accuracy is not null and not (p_accuracy between 0 and 100000)) then
    raise exception 'Invalid coordinates';
  end if;
  if v_time > now() + interval '30 seconds' or v_time < now() - interval '2 minutes' then
    raise exception 'Stale or future timestamp' using errcode = 'TR003';
  end if;

  select * into v_session from public.location_sessions
  where id = p_session and worker_id = v_actor and status = 'active'
  for update;
  if not found then
    raise exception 'No active session' using errcode = 'TR001';
  end if;
  if v_session.device_id is not null and p_device_id is not null
     and v_session.device_id <> p_device_id then
    raise exception 'Location sharing moved to another device' using errcode = 'TR002';
  end if;

  insert into public.worker_locations
    (worker_id, session_id, latitude, longitude, accuracy_meters, heading, speed, recorded_at, received_at)
  values (v_actor, p_session, p_lat, p_lng, p_accuracy,
          case when p_heading >= 0 then p_heading end,
          case when p_speed >= 0 then p_speed end,
          v_time, now())
  on conflict (worker_id) do update set
    session_id = excluded.session_id,
    latitude = excluded.latitude,
    longitude = excluded.longitude,
    accuracy_meters = excluded.accuracy_meters,
    heading = excluded.heading,
    speed = excluded.speed,
    recorded_at = excluded.recorded_at,
    received_at = now()
  where public.worker_locations.session_id <> excluded.session_id
     or public.worker_locations.recorded_at < excluded.recorded_at;
  get diagnostics v_rows = row_count;
  return v_rows > 0;
end;
$$;

-- Stops an active session: the worker (their own) or an admin. Deletes the
-- stored position. Repeating the call on a stopped session does nothing.
drop function if exists public.tracking_stop_session(uuid);
create or replace function public.tracking_stop_session(
  p_session uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_session public.location_sessions%rowtype;
  v_is_admin boolean := private.tracking_is_admin(v_actor);
  v_by_worker boolean;
begin
  select * into v_session from public.location_sessions where id = p_session for update;
  if not found then
    raise exception 'No active session' using errcode = 'TR001';
  end if;
  v_by_worker := v_session.worker_id = v_actor;
  if not (v_is_admin or (v_by_worker and private.tracking_is_worker(v_actor))) then
    raise exception 'Not authorized';
  end if;
  if v_session.status <> 'active' then
    return;
  end if;

  update public.location_sessions
  set status = 'stopped',
      ended_at = now(),
      end_reason = coalesce(nullif(p_reason, ''),
        case when v_by_worker then 'Stopped by worker' else 'Cancelled by administrator' end)
  where id = p_session;
  delete from public.worker_locations where worker_id = v_session.worker_id and session_id = p_session;
end;
$$;

-- Withdraws a pending request (any tracking admin). Idempotent.
create or replace function public.tracking_cancel_request(p_request uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.tracking_is_admin(auth.uid()) then
    raise exception 'Not authorized';
  end if;
  update public.location_requests
  set status = 'cancelled', responded_at = now(), end_reason = 'Cancelled by administrator'
  where id = p_request and status = 'pending';
end;
$$;

-- The worker confirms arrival at the branch. The ticket is not changed.
create or replace function public.tracking_mark_arrived(p_session uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.tracking_is_worker(auth.uid()) then
    raise exception 'Not authorized';
  end if;
  update public.location_sessions
  set arrived_at = coalesce(arrived_at, now())
  where id = p_session and worker_id = auth.uid() and status = 'active';
  if not found then
    raise exception 'No active session' using errcode = 'TR001';
  end if;
end;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'tracking_request_location(uuid, bigint)',
    'tracking_respond_request(uuid, boolean, text)',
    'tracking_start_session(uuid, text)',
    'tracking_update_location(uuid, double precision, double precision, double precision, timestamptz, double precision, double precision, text)',
    'tracking_stop_session(uuid, text)',
    'tracking_cancel_request(uuid)',
    'tracking_mark_arrived(uuid)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 6. Ticket reassigned or closed -> end the tracking tied to it
-- ---------------------------------------------------------------------------
create or replace function public.tracking_end_for_ticket()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reason text;
begin
  if new.engineer is distinct from old.engineer then
    v_reason := 'Ticket reassigned';
  elsif coalesce(new.status, '') in ('Completed', 'Canceled', 'Rejected')
        and new.status is distinct from old.status then
    v_reason := 'Ticket closed';
  else
    return new;
  end if;

  update public.location_requests
  set status = 'cancelled', responded_at = now(), end_reason = v_reason
  where ticket_id = new.id and status = 'pending';

  delete from public.worker_locations l
  using public.location_sessions s, public.location_requests r
  where l.session_id = s.id and r.id = s.request_id
    and r.ticket_id = new.id and s.status = 'active';

  update public.location_sessions s
  set status = 'stopped', ended_at = now(), end_reason = v_reason
  from public.location_requests r
  where r.id = s.request_id and r.ticket_id = new.id and s.status = 'active';
  return new;
end;
$$;
revoke all on function public.tracking_end_for_ticket() from public, anon, authenticated;

drop trigger if exists tracking_end_for_ticket on public.tickets;
create trigger tracking_end_for_ticket
  after update of engineer, status on public.tickets
  for each row execute function public.tracking_end_for_ticket();

-- ---------------------------------------------------------------------------
-- 7. Realtime: session start/stop must reach the app (requests and
--    locations are already published).
-- ---------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'location_sessions'
     ) then
    alter publication supabase_realtime add table public.location_sessions;
  end if;
end $$;

commit;
