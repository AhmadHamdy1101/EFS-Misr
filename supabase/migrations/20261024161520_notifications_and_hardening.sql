-- Notifications (persistent in-app + push outbox) and storage hardening.
--
-- Deployment order (each file once, in this order):
--   1. 20261024161312_security_and_performance.sql   (RLS, totals trigger fix)
--   2. 20261024161406_live_location_tracking.sql     (tracking fixes/extension)
--   3. this file
--   4. 20261024161534_drop_users_password.sql        (destructive, needs approval)
--
-- Additive except for the storage policies on bucket `images`, which are
-- replaced. No rows are deleted or rewritten.
--
-- Rollback: drop the triggers `notify_*`, the functions created here, and
-- the tables `notifications` and `push_tokens` (nothing else depends on
-- them); restore the four storage policies listed in section A.

begin;

-- ===========================================================================
-- A. Profile photos (bucket `images`)
-- ===========================================================================
-- Live state: policies "Public 1ffg0oo_0..3" let every signed-in user update
-- and delete ANY file in the bucket. The app names files
-- "<auth uid>-<time>.<ext>", so writes are limited to the caller's own files.
-- Reading stays open (the bucket is public; photo URLs are shown in lists).
drop policy if exists "Public 1ffg0oo_0" on storage.objects;
drop policy if exists "Public 1ffg0oo_1" on storage.objects;
drop policy if exists "Public 1ffg0oo_2" on storage.objects;
drop policy if exists "Public 1ffg0oo_3" on storage.objects;

drop policy if exists images_select on storage.objects;
create policy images_select on storage.objects
  for select to authenticated
  using (bucket_id = 'images');

drop policy if exists images_insert_own on storage.objects;
create policy images_insert_own on storage.objects
  for insert to authenticated
  with check (bucket_id = 'images' and name like (select auth.uid())::text || '-%');

drop policy if exists images_update_own on storage.objects;
create policy images_update_own on storage.objects
  for update to authenticated
  using (bucket_id = 'images' and name like (select auth.uid())::text || '-%')
  with check (bucket_id = 'images' and name like (select auth.uid())::text || '-%');

drop policy if exists images_delete_own on storage.objects;
create policy images_delete_own on storage.objects
  for delete to authenticated
  using (bucket_id = 'images' and name like (select auth.uid())::text || '-%');

-- ===========================================================================
-- B. Notifications
-- ===========================================================================

create table if not exists public.notifications (
  id bigint generated always as identity primary key,
  recipient_id uuid not null references auth.users (id) on delete cascade,
  actor_id uuid references auth.users (id) on delete set null,
  type text not null,
  -- 'operational' notifications are always delivered; 'info' ones could be
  -- muted by a future preference without hiding operational alerts.
  category text not null default 'operational' check (category in ('operational', 'info')),
  title text not null,
  body text not null,
  title_ar text,
  body_ar text,
  -- Navigation hints only (ids). Never coordinates or secrets; the app
  -- re-reads the target with the user's own permissions before opening it.
  data jsonb not null default '{}'::jsonb,
  ticket_id bigint references public.tickets (id) on delete cascade,
  location_request_id uuid references public.location_requests (id) on delete cascade,
  location_session_id uuid references public.location_sessions (id) on delete cascade,
  -- Stable per event and recipient: a trigger that fires twice for the same
  -- event cannot create two notifications.
  event_key text not null,
  created_at timestamptz not null default now(),
  read_at timestamptz,
  expires_at timestamptz not null default now() + interval '90 days',
  -- Push outbox state, owned by the `send-push` edge function.
  push_status text not null default 'pending'
    check (push_status in ('pending', 'sending', 'sent', 'failed', 'skipped')),
  push_attempts integer not null default 0,
  push_last_error text,
  push_updated_at timestamptz,
  constraint notifications_event_unique unique (recipient_id, event_key)
);

create index if not exists notifications_recipient_created_idx
  on public.notifications (recipient_id, created_at desc, id desc);
create index if not exists notifications_recipient_unread_idx
  on public.notifications (recipient_id) where read_at is null;
create index if not exists notifications_push_queue_idx
  on public.notifications (created_at) where push_status in ('pending', 'sending', 'failed');
create index if not exists notifications_ticket_idx on public.notifications (ticket_id);

alter table public.notifications enable row level security;
revoke all on table public.notifications from anon;
revoke insert, update, delete, truncate on table public.notifications from authenticated;
drop policy if exists notifications_select_own on public.notifications;
create policy notifications_select_own on public.notifications
  for select to authenticated
  using (recipient_id = (select auth.uid()));
-- No client insert/update/delete: rows come from triggers, read state from
-- the functions below.

create table if not exists public.push_tokens (
  token text primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  platform text not null check (platform in ('android', 'ios', 'web')),
  locale text not null default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists push_tokens_user_idx on public.push_tokens (user_id);

alter table public.push_tokens enable row level security;
revoke all on table public.push_tokens from anon;
revoke insert, update, delete, truncate on table public.push_tokens from authenticated;
drop policy if exists push_tokens_select_own on public.push_tokens;
create policy push_tokens_select_own on public.push_tokens
  for select to authenticated using (user_id = (select auth.uid()));

-- Realtime: new notifications appear without polling (RLS applies).
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime')
     and not exists (
       select 1 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'notifications'
     ) then
    alter publication supabase_realtime add table public.notifications;
  end if;
end $$;

-- ---------------------------------------------------------------------------
-- B1. Client functions
-- ---------------------------------------------------------------------------
create or replace function public.notifications_mark_read(p_ids bigint[])
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  update public.notifications
  set read_at = now()
  where recipient_id = auth.uid() and id = any (p_ids) and read_at is null;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

create or replace function public.notifications_mark_all_read()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_count integer;
begin
  update public.notifications
  set read_at = now()
  where recipient_id = auth.uid() and read_at is null;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- A device token belongs to whoever is signed in on it now; signing in as
-- another user on the same phone moves it.
create or replace function public.register_push_token(
  p_token text,
  p_platform text,
  p_locale text default 'en'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Not signed in.';
  end if;
  if p_token is null or length(p_token) < 20 or length(p_token) > 4096 then
    raise exception 'Invalid push token.';
  end if;
  insert into public.push_tokens (token, user_id, platform, locale)
  values (p_token, auth.uid(), p_platform, coalesce(nullif(p_locale, ''), 'en'))
  on conflict (token) do update
  set user_id = excluded.user_id,
      platform = excluded.platform,
      locale = excluded.locale,
      updated_at = now();
end;
$$;

create or replace function public.unregister_push_token(p_token text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.push_tokens where token = p_token and user_id = auth.uid();
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'notifications_mark_read(bigint[])',
    'notifications_mark_all_read()',
    'register_push_token(text, text, text)',
    'unregister_push_token(text)'
  ] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- B2. Push outbox functions (service role only, used by `send-push`)
-- ---------------------------------------------------------------------------

-- Claims up to p_limit notifications for sending. SKIP LOCKED lets several
-- function invocations run at once without sending the same row twice;
-- rows stuck in 'sending' (crashed worker) are retried after 5 minutes.
create or replace function public.push_claim_batch(p_limit integer default 50)
returns table (
  id bigint,
  recipient_id uuid,
  type text,
  title text,
  body text,
  title_ar text,
  body_ar text,
  data jsonb,
  tokens jsonb
)
language plpgsql
security definer
set search_path = public
as $$
#variable_conflict use_column
begin
  return query
  with claimable as (
    select n.id
    from public.notifications n
    where n.created_at > now() - interval '1 day'
      and n.push_attempts < 5
      and (
        n.push_status in ('pending', 'failed')
        or (n.push_status = 'sending' and n.push_updated_at < now() - interval '5 minutes')
      )
    order by n.created_at
    limit p_limit
    for update skip locked
  ),
  claimed as (
    update public.notifications n
    set push_status = 'sending',
        push_attempts = n.push_attempts + 1,
        push_updated_at = now()
    from claimable c
    where n.id = c.id
    returning n.*
  )
  select c.id, c.recipient_id, c.type, c.title, c.body, c.title_ar, c.body_ar, c.data,
         coalesce(
           (select jsonb_agg(jsonb_build_object('token', t.token, 'platform', t.platform, 'locale', t.locale))
            from public.push_tokens t where t.user_id = c.recipient_id),
           '[]'::jsonb
         )
  from claimed c;
end;
$$;

create or replace function public.push_mark_result(
  p_id bigint,
  p_status text,
  p_error text default null
)
returns void
language sql
security definer
set search_path = public
as $$
  update public.notifications
  set push_status = p_status,
      push_last_error = left(p_error, 500),
      push_updated_at = now()
  where id = p_id and p_status in ('sent', 'failed', 'skipped');
$$;

create or replace function public.push_remove_token(p_token text)
returns void
language sql
security definer
set search_path = public
as $$
  delete from public.push_tokens where token = p_token;
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'push_claim_batch(integer)',
    'push_mark_result(bigint, text, text)',
    'push_remove_token(text)'
  ] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
    execute format('grant execute on function public.%s to service_role', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- B3. Notification helpers (called only from the triggers below)
-- ---------------------------------------------------------------------------

-- Inserts one notification. Skips the person who caused the event, users
-- without an account link, and disabled staff. Duplicates are ignored.
create or replace function public.notify_user(
  p_recipient uuid,
  p_type text,
  p_event_key text,
  p_title text,
  p_body text,
  p_title_ar text,
  p_body_ar text,
  p_data jsonb default '{}'::jsonb,
  p_ticket_id bigint default null,
  p_request_id uuid default null,
  p_session_id uuid default null,
  p_category text default 'operational'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_recipient is null or p_recipient = auth.uid() then
    return;
  end if;
  if exists (
    select 1 from public.users
    where userid = p_recipient and coalesce(status, 1) in (3, 4)
  ) then
    return;
  end if;
  insert into public.notifications (
    recipient_id, actor_id, type, category, title, body, title_ar, body_ar, data,
    ticket_id, location_request_id, location_session_id, event_key
  ) values (
    p_recipient, auth.uid(), p_type, p_category, p_title, p_body, p_title_ar, p_body_ar,
    coalesce(p_data, '{}'::jsonb) || jsonb_build_object('type', p_type),
    p_ticket_id, p_request_id, p_session_id, p_event_key
  )
  on conflict (recipient_id, event_key) do nothing;
end;
$$;

create or replace function public.notify_admins(
  p_type text,
  p_event_key text,
  p_title text,
  p_body text,
  p_title_ar text,
  p_body_ar text,
  p_data jsonb default '{}'::jsonb,
  p_ticket_id bigint default null,
  p_request_id uuid default null,
  p_session_id uuid default null,
  p_category text default 'operational'
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin uuid;
begin
  for v_admin in
    select userid from public.users
    where role = 'Admin' and userid is not null and coalesce(status, 1) not in (3, 4)
  loop
    perform public.notify_user(
      v_admin, p_type, p_event_key, p_title, p_body, p_title_ar, p_body_ar,
      p_data, p_ticket_id, p_request_id, p_session_id, p_category
    );
  end loop;
end;
$$;

create or replace function public.user_uid(p_user_id bigint)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select userid from public.users where id = p_user_id;
$$;

create or replace function public.user_name(p_uid uuid)
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select nullif(name, '') from public.users where userid = p_uid),
    'A technician'
  );
$$;

do $$
declare
  f text;
begin
  foreach f in array array[
    'notify_user(uuid, text, text, text, text, text, text, jsonb, bigint, uuid, uuid, text)',
    'notify_admins(text, text, text, text, text, text, jsonb, bigint, uuid, uuid, text)',
    'user_uid(bigint)',
    'user_name(uuid)'
  ] loop
    execute format('revoke all on function public.%s from public, anon, authenticated', f);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- B4. Ticket events
-- ---------------------------------------------------------------------------
create or replace function public.notify_ticket_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ref text := '#' || coalesce(new.orecal_id::text, new.id::text);
  v_branch text := coalesce((select name from public.branch where id = new.branch), '');
  v_data jsonb := jsonb_build_object('ticket_id', new.id);
  v_tx text := txid_current()::text;
  v_engineer uuid := public.user_uid(new.engineer);
begin
  if tg_op = 'INSERT' then
    if new.engineer is not null then
      perform public.notify_user(
        v_engineer, 'ticket.assigned', 'ticket.assigned:' || new.id || ':' || v_tx,
        'New ticket assigned', 'Ticket ' || v_ref || ' at ' || v_branch || ' was assigned to you.',
        'تذكرة جديدة', 'تم إسناد التذكرة ' || v_ref || ' في ' || v_branch || ' إليك.',
        v_data, new.id);
    else
      perform public.notify_admins(
        'ticket.unassigned', 'ticket.unassigned:' || new.id || ':' || v_tx,
        'Ticket awaiting assignment', 'Ticket ' || v_ref || ' at ' || v_branch || ' has no technician.',
        'تذكرة بانتظار الإسناد', 'التذكرة ' || v_ref || ' في ' || v_branch || ' بدون فني.',
        v_data, new.id);
    end if;
    return new;
  end if;

  -- Reassigned: tell the new and the previous engineer.
  if new.engineer is distinct from old.engineer then
    if new.engineer is not null then
      perform public.notify_user(
        v_engineer, 'ticket.assigned', 'ticket.assigned:' || new.id || ':' || v_tx,
        'Ticket assigned to you', 'Ticket ' || v_ref || ' at ' || v_branch || ' was assigned to you.',
        'تم إسناد تذكرة إليك', 'تم إسناد التذكرة ' || v_ref || ' في ' || v_branch || ' إليك.',
        v_data, new.id);
    end if;
    if old.engineer is not null then
      perform public.notify_user(
        public.user_uid(old.engineer), 'ticket.reassigned', 'ticket.reassigned:' || new.id || ':' || v_tx,
        'Ticket reassigned', 'Ticket ' || v_ref || ' is no longer assigned to you.',
        'تمت إعادة إسناد التذكرة', 'التذكرة ' || v_ref || ' لم تعد مسندة إليك.',
        v_data, new.id);
    end if;
  end if;

  if new.status is distinct from old.status then
    case coalesce(new.status, '')
      when 'Completed' then
        perform public.notify_admins(
          'ticket.completed', 'ticket.completed:' || new.id || ':' || v_tx,
          'Ticket completed', 'Ticket ' || v_ref || ' at ' || v_branch || ' was completed.',
          'اكتملت التذكرة', 'اكتملت التذكرة ' || v_ref || ' في ' || v_branch || '.',
          v_data, new.id);
        perform public.notify_user(
          v_engineer, 'ticket.completed', 'ticket.completed:' || new.id || ':' || v_tx,
          'Ticket completed', 'Ticket ' || v_ref || ' was marked completed.',
          'اكتملت التذكرة', 'تم تحديد التذكرة ' || v_ref || ' كمكتملة.',
          v_data, new.id);
      when 'Canceled' then
        perform public.notify_user(
          v_engineer, 'ticket.cancelled', 'ticket.cancelled:' || new.id || ':' || v_tx,
          'Ticket cancelled', 'Ticket ' || v_ref || ' at ' || v_branch || ' was cancelled.',
          'تم إلغاء التذكرة', 'تم إلغاء التذكرة ' || v_ref || ' في ' || v_branch || '.',
          v_data, new.id);
        perform public.notify_admins(
          'ticket.cancelled', 'ticket.cancelled:' || new.id || ':' || v_tx,
          'Ticket cancelled', 'Ticket ' || v_ref || ' at ' || v_branch || ' was cancelled.',
          'تم إلغاء التذكرة', 'تم إلغاء التذكرة ' || v_ref || ' في ' || v_branch || '.',
          v_data, new.id, null, null, 'info');
      when 'Rejected' then
        perform public.notify_user(
          v_engineer, 'ticket.rejected', 'ticket.rejected:' || new.id || ':' || v_tx,
          'Ticket rejected', 'Ticket ' || v_ref || ' was rejected.',
          'تم رفض التذكرة', 'تم رفض التذكرة ' || v_ref || '.',
          v_data, new.id);
        perform public.notify_admins(
          'ticket.rejected', 'ticket.rejected:' || new.id || ':' || v_tx,
          'Ticket rejected', 'Ticket ' || v_ref || ' at ' || v_branch || ' was rejected.',
          'تم رفض التذكرة', 'تم رفض التذكرة ' || v_ref || ' في ' || v_branch || '.',
          v_data, new.id);
      when 'Awaiting' then
        perform public.notify_user(
          v_engineer, 'ticket.reopened', 'ticket.reopened:' || new.id || ':' || v_tx,
          'Ticket reopened', 'Ticket ' || v_ref || ' is open again.',
          'أعيد فتح التذكرة', 'التذكرة ' || v_ref || ' مفتوحة مرة أخرى.',
          v_data, new.id);
      else
        null;
    end case;
  end if;

  if new.priority is distinct from old.priority and new.engineer is not null then
    perform public.notify_user(
      v_engineer, 'ticket.priority_changed', 'ticket.priority:' || new.id || ':' || v_tx,
      'Ticket priority changed',
      'Ticket ' || v_ref || ' priority is now ' || coalesce(new.priority, '-') || '.',
      'تغيرت أولوية التذكرة',
      'أولوية التذكرة ' || v_ref || ' الآن ' || coalesce(new.priority, '-') || '.',
      v_data, new.id);
  end if;
  return new;
end;
$$;

drop trigger if exists notify_ticket_change on public.tickets;
create trigger notify_ticket_change
  after insert or update of engineer, status, priority on public.tickets
  for each row execute function public.notify_ticket_change();

-- ---------------------------------------------------------------------------
-- B5. Live-tracking events (positions themselves never notify)
-- ---------------------------------------------------------------------------
create or replace function public.notify_location_request_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_ticket text := case when new.ticket_id is null then ''
    else ' for ticket #' || coalesce((select orecal_id::text from public.tickets where id = new.ticket_id), new.ticket_id::text) end;
  v_ticket_ar text := case when new.ticket_id is null then ''
    else ' للتذكرة #' || coalesce((select orecal_id::text from public.tickets where id = new.ticket_id), new.ticket_id::text) end;
  v_worker_name text := public.user_name(new.worker_id);
  v_data jsonb := jsonb_build_object(
    'request_id', new.id,
    'ticket_id', new.ticket_id,
    'technician_id', (select id from public.users where userid = new.worker_id)
  );
begin
  if tg_op = 'INSERT' then
    perform public.notify_user(
      new.worker_id, 'tracking.requested', 'tracking.requested:' || new.id,
      'Live location request', 'An administrator asked to see your live location' || v_ticket || '.',
      'طلب موقع مباشر', 'طلب أحد المسؤولين رؤية موقعك المباشر' || v_ticket_ar || '.',
      v_data, new.ticket_id, new.id);
    return new;
  end if;

  if new.status is not distinct from old.status then
    return new;
  end if;
  case new.status
    when 'accepted' then
      perform public.notify_user(
        new.admin_id, 'tracking.accepted', 'tracking.accepted:' || new.id,
        'Live location shared', v_worker_name || ' accepted and is sharing live location' || v_ticket || '.',
        'تمت مشاركة الموقع', v_worker_name || ' وافق ويشارك موقعه المباشر' || v_ticket_ar || '.',
        v_data, new.ticket_id, new.id);
    when 'declined' then
      perform public.notify_user(
        new.admin_id, 'tracking.declined', 'tracking.declined:' || new.id,
        'Location request declined', v_worker_name || ' declined the location request' || v_ticket || '.',
        'تم رفض طلب الموقع', v_worker_name || ' رفض طلب الموقع' || v_ticket_ar || '.',
        v_data, new.ticket_id, new.id);
    when 'expired' then
      perform public.notify_user(
        new.admin_id, 'tracking.expired', 'tracking.expired:' || new.id,
        'Location request expired', 'The location request to ' || v_worker_name || ' expired without an answer.',
        'انتهت صلاحية طلب الموقع', 'انتهت صلاحية طلب الموقع المرسل إلى ' || v_worker_name || ' دون رد.',
        v_data, new.ticket_id, new.id, null, 'info');
    when 'cancelled' then
      perform public.notify_user(
        new.worker_id, 'tracking.cancelled', 'tracking.cancelled:' || new.id,
        'Location request cancelled', 'The location request' || v_ticket || ' was cancelled.',
        'تم إلغاء طلب الموقع', 'تم إلغاء طلب الموقع' || v_ticket_ar || '.',
        v_data, new.ticket_id, new.id, null, 'info');
    else
      null;
  end case;
  return new;
end;
$$;

drop trigger if exists notify_location_request_change on public.location_requests;
create trigger notify_location_request_change
  after insert or update of status on public.location_requests
  for each row execute function public.notify_location_request_change();

create or replace function public.notify_location_session_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin uuid := (select admin_id from public.location_requests where id = new.request_id);
  v_worker_name text := public.user_name(new.worker_id);
  v_data jsonb := jsonb_build_object(
    'session_id', new.id,
    'request_id', new.request_id,
    'technician_id', (select id from public.users where userid = new.worker_id)
  );
begin
  if tg_op = 'INSERT' then
    -- Request-based sessions are announced by the request's 'accepted'.
    if new.source = 'worker' then
      perform public.notify_admins(
        'tracking.started', 'tracking.started:' || new.id,
        'Live location started', v_worker_name || ' started sharing live location.',
        'بدأت مشاركة الموقع', 'بدأ ' || v_worker_name || ' مشاركة موقعه المباشر.',
        v_data, null, null, new.id, 'info');
    end if;
    return new;
  end if;

  if new.arrived_at is not null and old.arrived_at is null then
    if v_admin is not null then
      perform public.notify_user(
        v_admin, 'tracking.arrived', 'tracking.arrived:' || new.id,
        'Technician arrived', v_worker_name || ' confirmed arrival at the branch.',
        'وصل الفني', 'أكد ' || v_worker_name || ' الوصول إلى الفرع.',
        v_data, null, new.request_id, new.id);
    else
      perform public.notify_admins(
        'tracking.arrived', 'tracking.arrived:' || new.id,
        'Technician arrived', v_worker_name || ' confirmed arrival at the branch.',
        'وصل الفني', 'أكد ' || v_worker_name || ' الوصول إلى الفرع.',
        v_data, null, new.request_id, new.id);
    end if;
  end if;

  if new.status = 'stopped' and old.status = 'active' then
    if new.end_reason = 'Stopped by worker' then
      if v_admin is not null then
        perform public.notify_user(
          v_admin, 'tracking.ended', 'tracking.ended:' || new.id,
          'Live location ended', v_worker_name || ' stopped sharing live location.',
          'انتهت مشاركة الموقع', 'أوقف ' || v_worker_name || ' مشاركة موقعه المباشر.',
          v_data, null, new.request_id, new.id, 'info');
      end if;
    else
      perform public.notify_user(
        new.worker_id, 'tracking.stopped', 'tracking.stopped:' || new.id,
        'Location sharing ended',
        'Location sharing ended: ' || coalesce(new.end_reason, 'stopped by an administrator') || '.',
        'انتهت مشاركة الموقع', 'تم إنهاء مشاركة موقعك.',
        v_data, null, new.request_id, new.id);
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists notify_location_session_change on public.location_sessions;
create trigger notify_location_session_change
  after insert or update of status, arrived_at on public.location_sessions
  for each row execute function public.notify_location_session_change();

-- Optional, for a scheduled job (e.g. pg_cron every 5 minutes):
--   select public.tracking_notify_stale();
-- Tells the requesting admin once per session when no position has arrived
-- for 10 minutes. Not scheduled by this migration.
create or replace function public.tracking_notify_stale()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  r record;
  v_count integer := 0;
begin
  for r in
    select s.id, s.worker_id, s.request_id, rq.admin_id,
           (select id from public.users where userid = s.worker_id) as technician_id
    from public.location_sessions s
    left join public.location_requests rq on rq.id = s.request_id
    left join public.worker_locations l on l.worker_id = s.worker_id and l.session_id = s.id
    where s.status = 'active'
      and coalesce(l.received_at, s.started_at) < now() - interval '10 minutes'
  loop
    if r.admin_id is not null then
      perform public.notify_user(
        r.admin_id, 'tracking.unavailable', 'tracking.unavailable:' || r.id,
        'Live location unavailable',
        public.user_name(r.worker_id) || ' has not sent a location for 10 minutes.',
        'الموقع المباشر غير متاح',
        'لم يرسل ' || public.user_name(r.worker_id) || ' موقعه منذ 10 دقائق.',
        jsonb_build_object('session_id', r.id, 'technician_id', r.technician_id),
        null, r.request_id, r.id, 'info');
      v_count := v_count + 1;
    end if;
  end loop;
  return v_count;
end;
$$;
revoke all on function public.tracking_notify_stale() from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- B6. Asset repairs: admins see money spent on assets.
-- ---------------------------------------------------------------------------
create or replace function public.notify_asset_repair()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_asset text := coalesce(
    (select coalesce(nullif(barcode, ''), name, id::text) from public.assets where id = new.assets_id),
    new.assets_id::text);
begin
  perform public.notify_admins(
    'asset.repair_recorded', 'asset.repair:' || new.id,
    'Repair recorded',
    'A repair of ' || coalesce(new.amount, 0) || ' EGP was recorded for asset ' || v_asset || '.',
    'تم تسجيل إصلاح',
    'تم تسجيل إصلاح بقيمة ' || coalesce(new.amount, 0) || ' جنيه للأصل ' || v_asset || '.',
    jsonb_build_object('asset_id', new.assets_id, 'ticket_id', new.ticket_id),
    new.ticket_id, null, null, 'info');
  return new;
end;
$$;

drop trigger if exists notify_asset_repair on public.assets_repair;
create trigger notify_asset_repair
  after insert on public.assets_repair
  for each row execute function public.notify_asset_repair();

-- Housekeeping, for a scheduled job: delete expired notifications.
--   delete from public.notifications where expires_at < now();

-- Trigger functions are not meant to be called over the API.
revoke all on function public.notify_ticket_change() from public, anon, authenticated;
revoke all on function public.notify_location_request_change() from public, anon, authenticated;
revoke all on function public.notify_location_session_change() from public, anon, authenticated;
revoke all on function public.notify_asset_repair() from public, anon, authenticated;

commit;
