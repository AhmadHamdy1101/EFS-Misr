-- Core security and data-integrity fixes, written against the live schema
-- inspected on 2026-10-24 (project cxjgprvhjrjbmrazvrsa).
--
-- Live state this fixes:
--   * users, tickets, assets, assets_repair, branch, positions had a policy
--     "public" FOR ALL TO public USING (true): anyone holding the anon key
--     (it ships in the APK) could read, change and delete them without
--     signing in. area / assets_tickets_details allowed every signed-in user
--     everything, including deletes.
--   * anon had full table privileges on all of these.
--   * users was in the realtime publication, streaming every row to anyone.
--   * trigger update_assets_tickets_total set tickets.amount to the total of
--     ONE asset instead of the whole ticket.
--   * trigger functions had a mutable search_path.
--
-- The plain-text users.password column is handled separately in
-- 20261024161534_drop_users_password.sql because it deletes data.
--
-- No rows are deleted. One data correction: tickets.amount is recomputed
-- from assets_repair (the value the fixed trigger maintains).
-- Rollback: recreate the old "public"/"Auth"/"all" policies and grants (not
-- recommended — they expose all data to unauthenticated clients).

begin;

-- ---------------------------------------------------------------------------
-- 1. Role helper. SECURITY DEFINER so policies can read users without
--    recursing into the users policies. Disabled staff (3/4) are not admins.
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.users
    where userid = auth.uid() and role = 'Admin' and coalesce(status, 1) not in (3, 4)
  );
$$;
revoke all on function public.is_admin() from public, anon;
grant execute on function public.is_admin() to authenticated;

-- Non-admins may edit their own profile (e.g. the photo) but never their
-- role, status or identity columns.
create or replace function public.guard_user_privileged_columns()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null or public.is_admin() then
    return new;
  end if;
  if new.role is distinct from old.role
     or new.status is distinct from old.status
     or new.userid is distinct from old.userid
     or new.email is distinct from old.email
     or new.id is distinct from old.id then
    raise exception 'Only admins can change role, status, userid or email';
  end if;
  return new;
end;
$$;
revoke all on function public.guard_user_privileged_columns() from public, anon, authenticated;

drop trigger if exists guard_user_privileged_columns on public.users;
create trigger guard_user_privileged_columns
  before update on public.users
  for each row execute function public.guard_user_privileged_columns();

-- ---------------------------------------------------------------------------
-- 2. Row-level security. All existing policies on these tables are replaced.
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
  p record;
begin
  foreach t in array array[
    'users', 'assets', 'tickets', 'assets_tickets_details', 'assets_repair',
    'branch', 'area', 'positions'
  ] loop
    execute format('alter table public.%I enable row level security', t);
    for p in select policyname from pg_policies where schemaname = 'public' and tablename = t loop
      execute format('drop policy %I on public.%I', p.policyname, t);
    end loop;
    -- Nothing in the app reads these before sign-in.
    execute format('revoke all on table public.%I from anon', t);
  end loop;
end $$;

-- users: signed-in staff can read the directory (names on tickets, worker
-- lists); only admins create/delete; each user may update their own row
-- (guarded by the trigger above). Account creation/deletion goes through the
-- admin edge functions with the service role.
create policy users_select on public.users
  for select to authenticated using (true);
create policy users_admin_insert on public.users
  for insert to authenticated with check ((select public.is_admin()));
create policy users_admin_delete on public.users
  for delete to authenticated using ((select public.is_admin()));
create policy users_update on public.users
  for update to authenticated
  using ((select public.is_admin()) or userid = (select auth.uid()))
  with check ((select public.is_admin()) or userid = (select auth.uid()));

-- Operational tables: any signed-in staff member can read and write (the
-- app has no per-role split for tickets/assets; decided 2026-10-25 to keep
-- it); deleting is admin-only.
do $$
declare
  t text;
begin
  foreach t in array array['assets', 'tickets', 'assets_tickets_details', 'assets_repair'] loop
    execute format('create policy %I on public.%I for select to authenticated using (true)', t || '_select', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (true)', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using (true) with check (true)', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using ((select public.is_admin()))', t || '_admin_delete', t);
  end loop;
end $$;

-- Lookup tables: read for everyone signed in, write for admins.
do $$
declare
  t text;
begin
  foreach t in array array['branch', 'area', 'positions'] loop
    execute format('create policy %I on public.%I for select to authenticated using (true)', t || '_select', t);
    execute format('create policy %I on public.%I for all to authenticated using ((select public.is_admin())) with check ((select public.is_admin()))', t || '_admin_write', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3. Realtime: the app never subscribes to users or positions; publishing
--    them only leaked user rows. (tickets stays: the ticket list uses it.)
-- ---------------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array['users', 'positions'] loop
    if exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = t
    ) then
      execute format('alter publication supabase_realtime drop table public.%I', t);
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 4. Repair totals (existing triggers on assets_repair). Fixed:
--    tickets.amount = all repairs of the ticket, not of one asset; fixed
--    search_path; not callable by anon.
-- ---------------------------------------------------------------------------
create or replace function public.update_assets_tickets_total()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_asset bigint := coalesce(new.assets_id, old.assets_id);
  v_ticket bigint := coalesce(new.ticket_id, old.ticket_id);
  v_old_ticket bigint := case when tg_op = 'UPDATE' then old.ticket_id end;
begin
  -- Total for this asset on this ticket.
  update public.assets_tickets_details
  set "Ammount" = (
    select coalesce(sum(amount), 0) from public.assets_repair
    where assets_id = v_asset and ticket_id = v_ticket
  )
  where assets_id = v_asset and "Tickets_id" = v_ticket;

  -- Total for the whole ticket (and the previous ticket if it moved).
  update public.tickets t
  set amount = (select coalesce(sum(amount), 0) from public.assets_repair r where r.ticket_id = t.id)
  where t.id in (v_ticket, v_old_ticket);

  return null;
end;
$$;

create or replace function public.update_single_asset_amount(p_asset_id bigint)
returns void
language plpgsql
set search_path = ''
as $$
begin
  update public.assets
  set amount = (select coalesce(sum(amount), 0) from public.assets_repair where assets_id = p_asset_id)
  where id = p_asset_id;
end;
$$;

create or replace function public.trigger_update_asset_amount()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op in ('UPDATE', 'DELETE') and old.assets_id is not null then
    perform public.update_single_asset_amount(old.assets_id);
  end if;
  if tg_op in ('INSERT', 'UPDATE') and new.assets_id is not null
     and new.assets_id is distinct from (case when tg_op = 'UPDATE' then old.assets_id end) then
    perform public.update_single_asset_amount(new.assets_id);
  end if;
  return null;
end;
$$;

create or replace function public.recalc_assets_amount()
returns void
language sql
set search_path = ''
as $$
  update public.assets as a
  set amount = sub.total_amount
  from (
    select assets_id, coalesce(sum(amount), 0) as total_amount
    from public.assets_repair
    group by assets_id
  ) as sub
  where a.id = sub.assets_id;
$$;

revoke all on function public.update_assets_tickets_total() from public, anon, authenticated;
revoke all on function public.trigger_update_asset_amount() from public, anon, authenticated;
revoke all on function public.update_single_asset_amount(bigint) from public, anon;
revoke all on function public.recalc_assets_amount() from public, anon, authenticated;

-- Correct ticket totals written by the old trigger.
update public.tickets t
set amount = s.total
from (
  select t2.id, coalesce(sum(r.amount), 0) as total
  from public.tickets t2
  left join public.assets_repair r on r.ticket_id = t2.id
  group by t2.id
) s
where s.id = t.id and coalesce(t.amount, 0) <> s.total;

-- ---------------------------------------------------------------------------
-- 5. Indexes for foreign keys and the app's filters.
-- ---------------------------------------------------------------------------
create index if not exists assets_branch_idx on public.assets ("Branch");
create index if not exists assets_created_at_idx on public.assets (created_at desc, id desc);
create index if not exists assets_repair_asset_ticket_idx on public.assets_repair (assets_id, ticket_id);
create index if not exists assets_repair_ticket_idx on public.assets_repair (ticket_id);
create index if not exists assets_tickets_details_asset_ticket_idx on public.assets_tickets_details (assets_id, "Tickets_id");
create index if not exists assets_tickets_details_ticket_idx on public.assets_tickets_details ("Tickets_id");
create index if not exists branch_area_idx on public.branch (area);
create index if not exists tickets_created_at_idx on public.tickets (created_at desc, id desc);
create index if not exists tickets_branch_idx on public.tickets (branch);
create index if not exists tickets_engineer_idx on public.tickets (engineer);
create index if not exists tickets_closed_by_idx on public.tickets (closed_by);
create index if not exists users_userid_idx on public.users (userid);
create index if not exists users_positions_idx on public.users (positions);
create index if not exists users_name_idx on public.users (name, id);

commit;
