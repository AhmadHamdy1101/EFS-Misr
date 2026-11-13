-- Tickets and live tracking are separate features (2026-10-28).
--
-- Before: a location request could be tied to a ticket (ticket details had
-- a Request / View card), and the trigger tracking_end_for_ticket cancelled
-- requests and stopped sharing when that ticket was reassigned or closed.
-- Now tracking is requested only from the tracking screen, and nothing a
-- ticket does starts or stops tracking.
--
-- Non-destructive: location_requests.ticket_id stays (0 rows used it on
-- 2026-10-28) and tracking_request_location keeps its p_ticket_id parameter
-- so installed builds keep working; the value is ignored.
-- Rollback: recreate the trigger
--   create trigger tracking_end_for_ticket after update on public.tickets
--     for each row execute function public.tracking_end_for_ticket();
-- and the previous function bodies (docs/live_tracking_previous_functions.sql
-- and git history of this file).

drop trigger if exists tracking_end_for_ticket on public.tickets;

create or replace function public.tracking_request_location(p_worker uuid, p_ticket_id bigint default null)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_id uuid;
begin
  -- p_ticket_id: ignored (kept for older app builds).
  if not private.tracking_is_admin(v_actor) then
    raise exception 'Only administrators can request live location.';
  end if;
  if not private.tracking_is_worker(p_worker) then
    raise exception 'This worker is not enabled for live tracking.';
  end if;
  perform private.tracking_lock_worker(p_worker);
  update public.location_requests
  set status = 'expired', responded_at = now(), end_reason = 'Request expired'
  where worker_id = p_worker and status = 'pending' and expires_at <= now();
  select id into v_id from public.location_sessions where worker_id = p_worker and status = 'active';
  if found then return v_id; end if;
  select id into v_id from public.location_requests where worker_id = p_worker and status = 'pending';
  if found then return v_id; end if;
  insert into public.location_requests (admin_id, worker_id) values (v_actor, p_worker)
  returning id into v_id;
  return v_id;
end;
$$;

create or replace function public.tracking_respond_request(p_request uuid, p_accept boolean, p_device_id text default null)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_row public.location_requests%rowtype;
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
  if not p_accept then
    update public.location_requests
    set status = 'declined', responded_at = now(), end_reason = 'Declined by worker'
    where id = p_request;
    return 'declined';
  end if;
  update public.location_requests set status = 'accepted', responded_at = now() where id = p_request;
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
