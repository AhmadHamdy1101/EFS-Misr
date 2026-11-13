-- One active device per account (2026-10-28). Newest sign-in wins.
--
-- Supabase issues an access token (JWT, ~1 h) and a refresh token per
-- session. Deleting a row in auth.sessions revokes its refresh tokens, but
-- an access token already issued stays valid until it expires because
-- PostgREST only checks the signature. So:
--
-- 1. public.claim_session(): called by the app right after sign-in. Reads
--    the session id from the signed JWT (never from a parameter), records
--    it as the account's active session, revokes every other auth session
--    of the account and unlinks its push tokens (the new device registers
--    its own right after). Serialized per account with an advisory lock, so
--    two near-simultaneous sign-ins end with exactly one session.
-- 2. public.session_is_current(): false for a signed-in caller whose JWT
--    session is not the recorded one. Enforced
--    - by a RESTRICTIVE policy on every public table (ANDed with the
--      existing policies, which stay unchanged), and
--    - inside the role helpers every SECURITY DEFINER RPC uses (app_role,
--      is_admin, my_user_id, tracking_is_admin/_is_worker/_can_view), so
--      tracking and ticket RPCs fail closed for a replaced session.
-- 3. public.user_sessions is readable by its owner and in realtime, so the
--    replaced device is told at once; public.session_status() lets it check
--    on start/resume.
--
-- Transition: an account with no row yet (never signed in with this app
-- version) is not restricted, so already-installed older builds keep
-- working until that account signs in with a new build.
-- Service-role / cron / trigger contexts (no auth.uid()) are not affected.

create table if not exists public.user_sessions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  session_id uuid not null,
  device_id text,
  claimed_at timestamptz not null default now()
);

alter table public.user_sessions enable row level security;
revoke all on table public.user_sessions from anon, authenticated;
grant select on table public.user_sessions to authenticated;
drop policy if exists user_sessions_select_own on public.user_sessions;
create policy user_sessions_select_own on public.user_sessions
  for select to authenticated using (user_id = (select auth.uid()));

-- Session id of the caller's verified JWT (null without one).
create or replace function public.jwt_session_id()
returns uuid
language sql
stable
set search_path = ''
as $$
  select nullif(auth.jwt() ->> 'session_id', '')::uuid;
$$;

create or replace function public.session_is_current()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is null
    or not exists (
      select 1 from public.user_sessions s
      where s.user_id = auth.uid()
        and s.session_id is distinct from public.jwt_session_id()
    );
$$;

-- 'current' | 'replaced' | 'unclaimed' for the caller's session.
create or replace function public.session_status()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when auth.uid() is null then null
    when not exists (select 1 from public.user_sessions s where s.user_id = auth.uid())
      then 'unclaimed'
    when public.session_is_current() then 'current'
    else 'replaced'
  end;
$$;

create or replace function public.claim_session(p_device_id text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_sid uuid := public.jwt_session_id();
begin
  if v_uid is null or v_sid is null then
    raise exception 'Not signed in.' using errcode = 'SE001';
  end if;
  perform pg_advisory_xact_lock(hashtextextended('claim_session:' || v_uid::text, 0));
  -- A session revoked by a concurrent sign-in can't take over again.
  if not exists (select 1 from auth.sessions where id = v_sid and user_id = v_uid) then
    raise exception 'This session has ended. Please sign in again.' using errcode = 'SE001';
  end if;
  insert into public.user_sessions (user_id, session_id, device_id, claimed_at)
  values (v_uid, v_sid, left(p_device_id, 200), now())
  on conflict (user_id) do update
    set session_id = excluded.session_id,
        device_id = excluded.device_id,
        claimed_at = excluded.claimed_at;
  delete from auth.sessions where user_id = v_uid and id <> v_sid;
  delete from public.push_tokens where user_id = v_uid;
end;
$$;

revoke all on function public.jwt_session_id() from public, anon;
revoke all on function public.session_is_current() from public, anon;
revoke all on function public.session_status() from public, anon;
revoke all on function public.claim_session(text) from public, anon;
grant execute on function public.jwt_session_id() to authenticated;
grant execute on function public.session_is_current() to authenticated;
grant execute on function public.session_status() to authenticated;
grant execute on function public.claim_session(text) to authenticated;

-- Restrictive policy on every public table: a replaced session reads and
-- writes nothing, whatever the other policies allow.
do $$
declare
  t text;
begin
  for t in
    select c.relname from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity
      and c.relname <> 'user_sessions'
  loop
    execute format('drop policy if exists %I on public.%I', 'current_session_only', t);
    execute format(
      'create policy %I on public.%I as restrictive for all to authenticated '
      'using ((select public.session_is_current())) '
      'with check ((select public.session_is_current()))',
      'current_session_only', t);
  end loop;
end $$;

-- Role helpers fail closed for a replaced session (same bodies plus the
-- session check).
create or replace function public.app_role()
returns text
language sql
stable
security definer
set search_path = ''
as $$
  select u.role from public.users u
  where u.userid = auth.uid() and coalesce(u.status, 1) not in (3, 4)
    and public.session_is_current()
  order by u.id limit 1;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.session_is_current() and exists (
    select 1 from public.users
    where userid = auth.uid() and role = 'Admin' and coalesce(status, 1) not in (3, 4)
  );
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
    and public.session_is_current()
  order by u.id limit 1;
$$;

create or replace function private.tracking_is_admin(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select p_user is not null and public.session_is_current() and (
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
  select p_user is not null and public.session_is_current()
    and exists (select 1 from public.users u where u.userid = p_user and coalesce(u.status, 1) not in (3, 4))
    and coalesce((select m.enabled and m.role = 'worker' from public.tracking_members m where m.user_id = p_user),
                 (select bool_or(u.role = 'Worker') from public.users u where u.userid = p_user), false);
$$;

create or replace function private.tracking_can_view(p_user uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.tracking_is_admin(p_user) or (
    public.session_is_current() and exists (
      select 1 from public.users u
      where u.userid = p_user and u.role = 'User' and coalesce(u.status, 1) not in (3, 4)
    )
  );
$$;

-- A replaced device must not re-link its push token to the account.
create or replace function public.register_push_token(p_token text, p_platform text, p_locale text default 'en')
returns void
language plpgsql
security definer
set search_path = 'public'
as $$
begin
  if auth.uid() is null then raise exception 'Not signed in.'; end if;
  if not public.session_is_current() then
    raise exception 'This session has ended. Please sign in again.' using errcode = 'SE001';
  end if;
  if p_token is null or length(p_token) < 20 or length(p_token) > 4096 then raise exception 'Invalid push token.'; end if;
  insert into public.push_tokens (token, user_id, platform, locale)
  values (p_token, auth.uid(), p_platform, coalesce(nullif(p_locale, ''), 'en'))
  on conflict (token) do update set user_id = excluded.user_id, platform = excluded.platform, locale = excluded.locale, updated_at = now();
end;
$$;

alter publication supabase_realtime add table public.user_sessions;
