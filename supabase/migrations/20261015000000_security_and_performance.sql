-- Security and performance fixes from the code review.
-- Apply with `supabase db push` (or paste into the SQL editor) BEFORE shipping
-- the matching app build: the app now relies on `add_asset_repair` and on the
-- `tickets_closed_by_fkey` relationship.

begin;

-- ---------------------------------------------------------------------------
-- 1. Stop storing plain-text passwords. Supabase Auth already keeps the hash.
-- ---------------------------------------------------------------------------
alter table public.users drop column if exists password;

-- ---------------------------------------------------------------------------
-- 2. Role helper used by RLS policies. SECURITY DEFINER so it can read `users`
--    without recursing into the users policies.
-- ---------------------------------------------------------------------------
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users
    where userid::text = auth.uid()::text and role = 'Admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

-- Non-admins may edit their own profile (e.g. the photo) but never their
-- role, status or identity columns.
create or replace function public.guard_user_privileged_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or public.is_admin() then
    return new;
  end if;
  if new.role is distinct from old.role
     or new.status is distinct from old.status
     or new.userid is distinct from old.userid
     or new.email is distinct from old.email then
    raise exception 'Only admins can change role, status, userid or email';
  end if;
  return new;
end;
$$;

drop trigger if exists guard_user_privileged_columns on public.users;
create trigger guard_user_privileged_columns
  before update on public.users
  for each row execute function public.guard_user_privileged_columns();

-- ---------------------------------------------------------------------------
-- 3. Row-level security. Existing policies on these tables are replaced so an
--    old "allow all" policy cannot silently re-open access.
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
  end loop;
end $$;

-- users: everyone signed in can read the directory; only admins manage it;
-- each user can update their own row (guarded by the trigger above).
create policy users_select on public.users
  for select to authenticated using (true);
create policy users_admin_insert on public.users
  for insert to authenticated with check (public.is_admin());
create policy users_admin_delete on public.users
  for delete to authenticated using (public.is_admin());
create policy users_update on public.users
  for update to authenticated
  using (public.is_admin() or userid::text = auth.uid()::text)
  with check (public.is_admin() or userid::text = auth.uid()::text);

-- Operational tables: any signed-in staff member can read and write;
-- deleting is admin-only.
do $$
declare
  t text;
begin
  foreach t in array array['assets', 'tickets', 'assets_tickets_details', 'assets_repair'] loop
    execute format('create policy %I on public.%I for select to authenticated using (true)', t || '_select', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (true)', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using (true) with check (true)', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using (public.is_admin())', t || '_admin_delete', t);
  end loop;
end $$;

-- Lookup tables: read for everyone signed in, write for admins.
do $$
declare
  t text;
begin
  foreach t in array array['branch', 'area', 'positions'] loop
    execute format('create policy %I on public.%I for select to authenticated using (true)', t || '_select', t);
    execute format('create policy %I on public.%I for all to authenticated using (public.is_admin()) with check (public.is_admin())', t || '_admin_write', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 4. Let PostgREST embed the "closed by" user in the tickets query instead of
--    a second round trip.
-- ---------------------------------------------------------------------------
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'tickets_closed_by_fkey'
  ) then
    alter table public.tickets
      add constraint tickets_closed_by_fkey
      foreign key (closed_by) references public.users (id) on delete set null;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- 5. Save a repair in one atomic call. The link row is locked so two
--    technicians saving at the same time cannot produce a wrong total.
-- ---------------------------------------------------------------------------
create or replace function public.add_asset_repair(
  p_asset_id bigint,
  p_ticket_id bigint,
  p_variation text,
  p_comment text,
  p_amount numeric
)
returns json
language plpgsql
security invoker
set search_path = public
as $$
declare
  v_repair public.assets_repair;
  v_total numeric;
begin
  perform 1
  from public.assets_tickets_details
  where assets_id = p_asset_id and "Tickets_id" = p_ticket_id
  for update;

  if not found then
    raise exception 'This asset is not linked to the selected ticket.';
  end if;

  insert into public.assets_repair (assets_id, ticket_id, variation, comment, amount)
  values (p_asset_id, p_ticket_id, p_variation, p_comment, p_amount)
  returning * into v_repair;

  select coalesce(sum(amount), 0) into v_total
  from public.assets_repair
  where assets_id = p_asset_id and ticket_id = p_ticket_id;

  update public.assets_tickets_details
  set "Ammount" = v_total
  where assets_id = p_asset_id and "Tickets_id" = p_ticket_id;

  return json_build_object(
    'repair', row_to_json(v_repair),
    'totals', json_build_object('asset_ticket_total', v_total)
  );
end;
$$;

grant execute on function public.add_asset_repair(bigint, bigint, text, text, numeric) to authenticated;

-- ---------------------------------------------------------------------------
-- 6. Indexes for the filters the app runs on every screen.
-- ---------------------------------------------------------------------------
create index if not exists assets_repair_asset_ticket_idx
  on public.assets_repair (assets_id, ticket_id);
create index if not exists assets_repair_ticket_idx
  on public.assets_repair (ticket_id);
create index if not exists assets_tickets_details_asset_ticket_idx
  on public.assets_tickets_details (assets_id, "Tickets_id");
create index if not exists assets_tickets_details_ticket_idx
  on public.assets_tickets_details ("Tickets_id");
create index if not exists tickets_created_at_idx
  on public.tickets (created_at desc);
create index if not exists users_userid_idx
  on public.users (userid);
create index if not exists assets_barcode_idx
  on public.assets (barcode);

commit;
