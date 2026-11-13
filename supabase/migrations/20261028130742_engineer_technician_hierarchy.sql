-- Engineer → Technician hierarchy (decided 2026-10-28).
--
-- Roles stay as they are: `User` is the Engineer, `Worker` the Technician.
-- A technician has at most one engineer: users.supervisor_id. One column
-- (not a link table) makes duplicate or conflicting assignments impossible.
--
-- Backward compatible: nullable column, no data rewritten, existing
-- policies unchanged (users are already readable by signed-in staff).
-- Applied to the live project 2026-10-28 (approved; dry run 9/9 passed).
-- Older app builds ignore the column.

alter table public.users
  add column if not exists supervisor_id bigint
    references public.users (id) on delete set null;

alter table public.users
  drop constraint if exists users_supervisor_not_self;
alter table public.users
  add constraint users_supervisor_not_self check (supervisor_id <> id);

create index if not exists users_supervisor_idx
  on public.users (supervisor_id) where supervisor_id is not null;

-- Only admins change it: same guard as role/status (non-admins may still
-- edit their own profile, e.g. the photo).
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
     or new.id is distinct from old.id
     or new.supervisor_id is distinct from old.supervisor_id then
    raise exception 'Only admins can change role, status, userid, email or engineer';
  end if;
  return new;
end;
$$;
revoke all on function public.guard_user_privileged_columns() from public, anon, authenticated;

-- A supervisor link is valid only from a Worker to an active User. When a
-- row stops being a Worker its link is dropped instead of failing the role
-- change; linking to a non-engineer is refused.
create or replace function public.check_user_supervisor()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.supervisor_id is null then
    return new;
  end if;
  if new.role is distinct from 'Worker' then
    new.supervisor_id := null;
    return new;
  end if;
  if not exists (
    select 1 from public.users s
    where s.id = new.supervisor_id
      and s.role = 'User'
      and coalesce(s.status, 0) not in (3, 4)
  ) then
    raise exception 'The engineer must be an active account with role User'
      using errcode = 'EH001';
  end if;
  return new;
end;
$$;
revoke all on function public.check_user_supervisor() from public, anon, authenticated;

drop trigger if exists check_user_supervisor on public.users;
create trigger check_user_supervisor
  before insert or update of supervisor_id, role on public.users
  for each row execute function public.check_user_supervisor();

-- An engineer who stops being an active User releases their technicians
-- (they show as "No engineer" until an admin reassigns them).
create or replace function public.release_supervised_users()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.role is distinct from 'User' or coalesce(new.status, 0) in (3, 4) then
    update public.users set supervisor_id = null where supervisor_id = new.id;
  end if;
  return null;
end;
$$;
revoke all on function public.release_supervised_users() from public, anon, authenticated;

drop trigger if exists release_supervised_users on public.users;
create trigger release_supervised_users
  after update of role, status on public.users
  for each row
  when (old.role is distinct from new.role or old.status is distinct from new.status)
  execute function public.release_supervised_users();
