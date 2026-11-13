-- Every active non-admin staff member can be tracked by default.
--
-- Before: only users with an enabled 'worker' row in tracking_members could be
-- listed, requested or share their location. tracking_members was empty, so
-- the admin screen showed no workers and technicians got "Not authorized".
--
-- Now (decided 2026-10-24): workers = users whose role is not 'Admin' and who
-- are not terminated/suspended. A tracking_members row still overrides:
--   enabled = false        -> excluded from tracking
--   role = 'admin'         -> a tracking admin, not a worker
--   role = 'worker'        -> a worker (also allowed for role 'Admin' users)
--
-- Also: the per-worker serialisation used `SELECT ... FROM tracking_members
-- FOR UPDATE`, which locks nothing when the worker has no row. It now uses a
-- transaction-scoped advisory lock on the worker id.
--
-- Additive: replaces functions and adds a view; no data changes.

begin;

create or replace function private.tracking_is_worker(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user is not null
    and exists (
      select 1 from public.users u
      where u.userid = p_user and coalesce(u.status, 1) not in (3, 4)
    )
    and coalesce(
      -- An explicit membership row decides.
      (select m.enabled and m.role = 'worker'
       from public.tracking_members m where m.user_id = p_user),
      -- Otherwise every non-admin staff member.
      (select bool_or(coalesce(u.role, '') <> 'Admin')
       from public.users u where u.userid = p_user),
      false
    );
$$;

create or replace function private.tracking_lock_worker(p_worker uuid)
returns void
language sql
security definer
set search_path = ''
as $$
  select pg_advisory_xact_lock(hashtextextended('tracking:' || p_worker::text, 0));
$$;
revoke all on function private.tracking_lock_worker(uuid) from public, anon, authenticated;

-- Who the admin screen lists (same rule as the functions; caller's RLS on
-- users applies, the eligibility check runs as definer).
create or replace view public.tracking_workers
with (security_invoker = true) as
select u.userid as user_id
from public.users u
where u.userid is not null and private.tracking_is_worker(u.userid);

revoke all on public.tracking_workers from anon;
grant select on public.tracking_workers to authenticated;

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
    raise exception 'Only administrators can request live location.';
  end if;
  if not private.tracking_is_worker(p_worker) then
    raise exception 'This worker is not enabled for live tracking.';
  end if;

  if p_ticket_id is not null then
    select id into v_worker_user from public.users where userid = p_worker limit 1;
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

  perform private.tracking_lock_worker(p_worker);

  update public.location_requests
  set status = 'expired', responded_at = now(), end_reason = 'Request expired'
  where worker_id = p_worker and status = 'pending' and expires_at <= now();

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
    raise exception 'You are not enabled for live tracking. Ask an administrator.';
  end if;
  perform private.tracking_lock_worker(v_actor);

  select * into v_row from public.location_requests where id = p_request for update;
  if not found or v_row.worker_id is distinct from v_actor then
    raise exception 'This request no longer exists.';
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
    select id into v_me_user from public.users where userid = v_actor limit 1;
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
    raise exception 'You are not enabled for live tracking. Ask an administrator.';
  end if;
  perform private.tracking_lock_worker(v_actor);

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

commit;
