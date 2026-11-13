-- Role-based access control, enforced in the database.
--
-- Roles (users.role, decided 2026-10-25):
--   Admin   full access
--   User    read-only: tickets, assets, repairs, live tracking (view only)
--   Worker  = Technician: sees ONLY tickets assigned to them (tickets.engineer);
--           on those it may set status Completed/Rejected (from Awaiting),
--           edit damage description / dates / attachment, link assets and
--           record repairs; shares its own location. Cannot create or delete
--           tickets/assets or change other ticket fields.
-- Terminated (3) / suspended (4) accounts get no access.
--
-- Replaces the open "any signed-in user may write" policies from
-- 20261024161312_security_and_performance.sql. No rows are changed.

begin;

-- ---------------------------------------------------------------------------
-- 1. Trusted role helpers (read from public.users, which only admins can
--    change role/status on — see guard_user_privileged_columns).
-- ---------------------------------------------------------------------------
create or replace function public.app_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select u.role from public.users u
  where u.userid = auth.uid() and coalesce(u.status, 1) not in (3, 4)
  order by u.id limit 1;
$$;

create or replace function public.my_user_id()
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select u.id from public.users u
  where u.userid = auth.uid() and coalesce(u.status, 1) not in (3, 4)
  order by u.id limit 1;
$$;

-- Ticket visible to the caller: admins and users see all, technicians only
-- their own.
create or replace function public.can_read_ticket(p_ticket bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(public.app_role() in ('Admin', 'User'), false)
    or exists (
      select 1 from public.tickets t
      where t.id = p_ticket and t.engineer = public.my_user_id()
        and public.app_role() = 'Worker'
    );
$$;

-- Caller may do maintenance work on the ticket (link assets, record repairs).
create or replace function public.can_work_ticket(p_ticket bigint)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_admin()
    or exists (
      select 1 from public.tickets t
      where t.id = p_ticket and t.engineer = public.my_user_id()
        and public.app_role() = 'Worker'
    );
$$;

do $$
declare
  f text;
begin
  foreach f in array array['app_role()', 'my_user_id()', 'can_read_ticket(bigint)', 'can_work_ticket(bigint)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 2. Policies
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
  p record;
begin
  foreach t in array array['tickets', 'assets', 'assets_tickets_details', 'assets_repair'] loop
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = t loop
      execute format('drop policy %I on public.%I', p.policyname, t);
    end loop;
  end loop;
end $$;

-- tickets
create policy tickets_select on public.tickets
  for select to authenticated
  using (
    (select public.app_role()) in ('Admin', 'User')
    or (
      (select public.app_role()) = 'Worker'
      and engineer = (select public.my_user_id())
    )
  );
create policy tickets_admin_insert on public.tickets
  for insert to authenticated
  with check ((select public.is_admin()));
create policy tickets_update on public.tickets
  for update to authenticated
  using (
    (select public.is_admin())
    or ((select public.app_role()) = 'Worker' and engineer = (select public.my_user_id()))
  )
  with check (
    (select public.is_admin())
    or ((select public.app_role()) = 'Worker' and engineer = (select public.my_user_id()))
  );
create policy tickets_admin_delete on public.tickets
  for delete to authenticated
  using ((select public.is_admin()));

-- assets: every active staff member can read (scan/look up); admins write.
create policy assets_select on public.assets
  for select to authenticated
  using ((select public.app_role()) is not null);
create policy assets_admin_write on public.assets
  for all to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));

-- assets_tickets_details (asset linked to a ticket)
create policy assets_tickets_details_select on public.assets_tickets_details
  for select to authenticated
  using (public.can_read_ticket("Tickets_id"));
create policy assets_tickets_details_insert on public.assets_tickets_details
  for insert to authenticated
  with check (public.can_work_ticket("Tickets_id"));
create policy assets_tickets_details_admin_update on public.assets_tickets_details
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));
create policy assets_tickets_details_admin_delete on public.assets_tickets_details
  for delete to authenticated
  using ((select public.is_admin()));

-- assets_repair (repairs / spare parts recorded on a ticket)
create policy assets_repair_select on public.assets_repair
  for select to authenticated
  using (
    (select public.app_role()) in ('Admin', 'User')
    or public.can_read_ticket(ticket_id)
  );
create policy assets_repair_insert on public.assets_repair
  for insert to authenticated
  with check (public.can_work_ticket(ticket_id));
create policy assets_repair_admin_update on public.assets_repair
  for update to authenticated
  using ((select public.is_admin()))
  with check ((select public.is_admin()));
create policy assets_repair_admin_delete on public.assets_repair
  for delete to authenticated
  using ((select public.is_admin()));

-- ---------------------------------------------------------------------------
-- 3. Technicians may only change their workflow fields on a ticket.
-- ---------------------------------------------------------------------------
create or replace function public.guard_ticket_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- Admins, server-side jobs, and updates made by other triggers (repair
  -- totals) are not restricted here.
  if auth.uid() is null or public.is_admin() or pg_trigger_depth() > 1 then
    return new;
  end if;

  if new.id is distinct from old.id
     or new.orecal_id is distinct from old.orecal_id
     or new.branch is distinct from old.branch
     or new.request_date is distinct from old.request_date
     or new.priority is distinct from old.priority
     or new.engineer is distinct from old.engineer
     or new.closed_by is distinct from old.closed_by
     or new.comment is distinct from old.comment
     or new.amount is distinct from old.amount
     or new.variation is distinct from old.variation
     or new.created_at is distinct from old.created_at then
    raise exception 'Technicians can only change the status, dates and damage description of their tickets.';
  end if;

  if new.status is distinct from old.status then
    if coalesce(old.status, '') <> 'Awaiting'
       or coalesce(new.status, '') not in ('Completed', 'Rejected') then
      raise exception 'Technicians can only mark an open ticket as Completed or Rejected.';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.guard_ticket_update() from public, anon, authenticated;

drop trigger if exists guard_ticket_update on public.tickets;
create trigger guard_ticket_update
  before update on public.tickets
  for each row execute function public.guard_ticket_update();

-- Repair totals are maintained by triggers; they must run with definer
-- rights now that technicians can't update assets / links / ticket amounts.
alter function public.update_assets_tickets_total() security definer;
alter function public.trigger_update_asset_amount() security definer;
alter function public.update_single_asset_amount(bigint) security definer;
revoke all on function public.update_single_asset_amount(bigint) from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 4. Live tracking: technicians (Worker) share; admins control; users view.
-- ---------------------------------------------------------------------------
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
      -- Otherwise technicians.
      (select bool_or(u.role = 'Worker') from public.users u where u.userid = p_user),
      false
    );
$$;

-- May see live locations (read only): tracking admins and users.
create or replace function private.tracking_can_view(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.tracking_is_admin(p_user)
    or exists (
      select 1 from public.users u
      where u.userid = p_user and u.role = 'User' and coalesce(u.status, 1) not in (3, 4)
    );
$$;
revoke all on function private.tracking_can_view(uuid) from public, anon;
grant execute on function private.tracking_can_view(uuid) to authenticated;

drop policy if exists tracking_members_read on public.tracking_members;
create policy tracking_members_read on public.tracking_members
  for select to authenticated
  using (user_id = (select auth.uid()) or (select private.tracking_can_view(auth.uid())));

drop policy if exists tracking_requests_read on public.location_requests;
create policy tracking_requests_read on public.location_requests
  for select to authenticated
  using (worker_id = (select auth.uid()) or (select private.tracking_can_view(auth.uid())));

drop policy if exists tracking_sessions_read on public.location_sessions;
create policy tracking_sessions_read on public.location_sessions
  for select to authenticated
  using (worker_id = (select auth.uid()) or (select private.tracking_can_view(auth.uid())));

drop policy if exists tracking_locations_read on public.worker_locations;
create policy tracking_locations_read on public.worker_locations
  for select to authenticated
  using (
    worker_id = (select auth.uid())
    or (
      (select private.tracking_can_view(auth.uid()))
      and exists (
        select 1 from public.location_sessions s
        where s.id = worker_locations.session_id and s.status = 'active'
      )
    )
  );

commit;
