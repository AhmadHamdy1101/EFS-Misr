-- Authorization and workflow checks, run AFTER the migrations inside the same
-- transaction and then ROLLED BACK (nothing is kept). Each check impersonates
-- a real account by setting the JWT claims and the database role, the same
-- way PostgREST does for app requests.
--
-- Run on the live project after applying the migrations (2026-10-24):
-- 27/27 checks passed (the live run also checked a stale fix -> TR003 and
-- that admins can list tracking_members). Usage: begin; <this file>; rollback;
create temp table _r (n serial, test text, expected text, result text) on commit drop;
do $$
declare
  v_admin uuid := (select userid from public.users where role = 'Admin' and status = 1 order by id limit 1);
  v_worker uuid := (select userid from public.users where role = 'Worker' order by id limit 1);
  v_worker_id bigint := (select id from public.users where role = 'Worker' order by id limit 1);
  v_other uuid := (select userid from public.users where role = 'User' order by id limit 1);
  v_branch bigint := (select id from public.branch order by id limit 1);
  v_req uuid;
  v_req2 uuid;
  v_sess uuid;
  v_txt text;
  v_n int;
  v_b boolean;
begin
  -- Test setup (rolled back): enable the worker for tracking.
  insert into public.tracking_members (user_id, role) values (v_worker, 'worker')
  on conflict (user_id) do update set role = 'worker', enabled = true;

  -- 1. anonymous (anon key, not signed in)
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  begin
    set local role anon;
    select count(*) into v_n from public.users;
    reset role; insert into _r (test, expected, result) values ('anon reads users', 'denied', 'ALLOWED ' || v_n);
  exception when others then reset role; insert into _r (test, expected, result) values ('anon reads users', 'denied', 'denied: ' || sqlerrm); end;
  begin
    set local role anon;
    select count(*) into v_n from public.tickets;
    reset role; insert into _r (test, expected, result) values ('anon reads tickets', 'denied', 'ALLOWED ' || v_n);
  exception when others then reset role; insert into _r (test, expected, result) values ('anon reads tickets', 'denied', 'denied: ' || sqlerrm); end;
  begin
    set local role anon;
    select count(*) into v_n from public.notifications;
    reset role; insert into _r (test, expected, result) values ('anon reads notifications', 'denied', 'ALLOWED ' || v_n);
  exception when others then reset role; insert into _r (test, expected, result) values ('anon reads notifications', 'denied', 'denied: ' || sqlerrm); end;
  begin
    set local role anon;
    perform public.tracking_request_location(v_worker);
    reset role; insert into _r (test, expected, result) values ('anon calls tracking_request_location', 'denied', 'ALLOWED');
  exception when others then reset role; insert into _r (test, expected, result) values ('anon calls tracking_request_location', 'denied', 'denied: ' || sqlerrm); end;

  -- 2. signed-in staff member who is neither admin nor tracking member
  perform set_config('request.jwt.claims', json_build_object('sub', v_other, 'role', 'authenticated')::text, true);
  begin
    set local role authenticated;
    perform public.tracking_request_location(v_worker);
    reset role; insert into _r (test, expected, result) values ('non-member requests location (old bypass)', 'denied', 'ALLOWED');
  exception when others then reset role; insert into _r (test, expected, result) values ('non-member requests location (old bypass)', 'denied', 'denied: ' || sqlerrm); end;
  begin
    set local role authenticated;
    update public.users set role = 'Admin' where userid = v_other;
    reset role; insert into _r (test, expected, result) values ('user makes self Admin', 'denied', 'ALLOWED');
  exception when others then reset role; insert into _r (test, expected, result) values ('user makes self Admin', 'denied', 'denied: ' || sqlerrm); end;
  begin
    set local role authenticated;
    with d as (delete from public.tickets returning 1) select count(*) into v_n from d;
    reset role; insert into _r (test, expected, result) values ('user deletes tickets', '0 rows', v_n || ' rows');
  exception when others then reset role; insert into _r (test, expected, result) values ('user deletes tickets', '0 rows', 'error: ' || sqlerrm); end;
  begin
    set local role authenticated;
    select count(*) into v_n from public.users;
    reset role; insert into _r (test, expected, result) values ('user reads staff directory', '> 0', v_n::text);
  exception when others then reset role; insert into _r (test, expected, result) values ('user reads staff directory', '> 0', 'error: ' || sqlerrm); end;
  begin
    set local role authenticated;
    insert into storage.objects (bucket_id, name) values ('images', v_admin::text || '-x.jpg');
    reset role; insert into _r (test, expected, result) values ('user uploads into another user''s photo name', 'denied', 'ALLOWED');
  exception when others then reset role; insert into _r (test, expected, result) values ('user uploads into another user''s photo name', 'denied', 'denied: ' || sqlerrm); end;
  begin
    set local role authenticated;
    insert into storage.objects (bucket_id, name) values ('images', v_other::text || '-x.jpg');
    reset role; insert into _r (test, expected, result) values ('user uploads own photo name', 'allowed', 'allowed');
  exception when others then reset role; insert into _r (test, expected, result) values ('user uploads own photo name', 'allowed', 'denied: ' || sqlerrm); end;

  -- 3. admin requests; duplicate request returns the same id
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  begin
    set local role authenticated;
    v_req := public.tracking_request_location(v_worker);
    v_req2 := public.tracking_request_location(v_worker);
    reset role; insert into _r (test, expected, result) values ('admin requests twice', 'same request', case when v_req = v_req2 then 'same request' else 'DUPLICATE' end);
  exception when others then reset role; insert into _r (test, expected, result) values ('admin requests twice', 'same request', 'error: ' || sqlerrm); end;

  -- 4. worker sees the request notification; accepts on device dev1
  perform set_config('request.jwt.claims', json_build_object('sub', v_worker, 'role', 'authenticated')::text, true);
  begin
    set local role authenticated;
    select count(*) into v_n from public.notifications where type = 'tracking.requested';
    reset role; insert into _r (test, expected, result) values ('worker got tracking.requested', '1', v_n::text);
  exception when others then reset role; insert into _r (test, expected, result) values ('worker got tracking.requested', '1', 'error: ' || sqlerrm); end;
  begin
    set local role authenticated;
    v_txt := public.tracking_respond_request(v_req, true, 'dev1');
    select id into v_sess from public.location_sessions where worker_id = v_worker and status = 'active';
    v_b := public.tracking_update_location(v_sess, 30.05, 31.24, 5, now(), null, null, 'dev1');
    reset role; insert into _r (test, expected, result) values ('worker accepts and publishes', 'active / true', v_txt || ' / ' || v_b);
  exception when others then reset role; insert into _r (test, expected, result) values ('worker accepts and publishes', 'active / true', 'error: ' || sqlerrm); end;
  begin
    set local role authenticated;
    perform public.tracking_update_location(v_sess, 30.06, 31.25, 5, now(), null, null, 'dev2');
    reset role; insert into _r (test, expected, result) values ('second device publishes', 'TR002', 'ALLOWED');
  exception when others then reset role; insert into _r (test, expected, result) values ('second device publishes', 'TR002', sqlstate); end;

  -- 5. other staff can't see the session or the position
  perform set_config('request.jwt.claims', json_build_object('sub', v_other, 'role', 'authenticated')::text, true);
  begin
    set local role authenticated;
    select (select count(*) from public.worker_locations) + (select count(*) from public.location_sessions)
         + (select count(*) from public.tracking_overview) into v_n;
    reset role; insert into _r (test, expected, result) values ('other user sees tracking rows', '0', v_n::text);
  exception when others then reset role; insert into _r (test, expected, result) values ('other user sees tracking rows', '0', 'error: ' || sqlerrm); end;
  begin
    set local role authenticated;
    perform public.tracking_update_location(v_sess, 1, 1, 5, now(), null, null, 'dev1');
    reset role; insert into _r (test, expected, result) values ('other user writes worker position', 'denied', 'ALLOWED');
  exception when others then reset role; insert into _r (test, expected, result) values ('other user writes worker position', 'denied', 'denied: ' || sqlerrm); end;
  begin
    set local role authenticated;
    select count(*) into v_n from public.notifications;
    reset role; insert into _r (test, expected, result) values ('other user reads notifications', '0', v_n::text);
  exception when others then reset role; insert into _r (test, expected, result) values ('other user reads notifications', '0', 'error: ' || sqlerrm); end;

  -- 6. admin sees the live position, the acceptance notice, then stops it
  perform set_config('request.jwt.claims', json_build_object('sub', v_admin, 'role', 'authenticated')::text, true);
  begin
    set local role authenticated;
    select count(*) into v_n from public.tracking_overview where worker_uid = v_worker::text and latitude is not null;
    reset role; insert into _r (test, expected, result) values ('admin sees live position', '1', v_n::text);
  exception when others then reset role; insert into _r (test, expected, result) values ('admin sees live position', '1', 'error: ' || sqlerrm); end;
  begin
    set local role authenticated;
    select count(*) into v_n from public.notifications where type = 'tracking.accepted';
    reset role; insert into _r (test, expected, result) values ('admin got tracking.accepted', '1', v_n::text);
  exception when others then reset role; insert into _r (test, expected, result) values ('admin got tracking.accepted', '1', 'error: ' || sqlerrm); end;
  begin
    set local role authenticated;
    perform public.tracking_stop_session(v_sess, null);
    reset role;
    select count(*) into v_n from public.worker_locations where worker_id = v_worker;
    insert into _r (test, expected, result) values ('admin stops session, position deleted', '0', v_n::text);
    select count(*) into v_n from public.notifications where recipient_id = v_worker and type = 'tracking.stopped';
    insert into _r (test, expected, result) values ('worker got tracking.stopped', '1', v_n::text);
  exception when others then reset role; insert into _r (test, expected, result) values ('admin stops session, position deleted', '0', 'error: ' || sqlerrm); end;
  begin
    set local role authenticated;
    insert into public.tickets (orecal_id, branch, engineer, priority, comment)
    values (999999, v_branch, v_worker_id, 'B', 'dry run');
    reset role;
    select count(*) into v_n from public.notifications where recipient_id = v_worker and type = 'ticket.assigned';
    insert into _r (test, expected, result) values ('new ticket notifies its engineer', '1', v_n::text);
  exception when others then reset role; insert into _r (test, expected, result) values ('new ticket notifies its engineer', '1', 'error: ' || sqlerrm); end;

  -- 7. data fixes
  select count(*) into v_n from public.tickets t
  where coalesce(t.amount, 0) <> coalesce((select sum(amount) from public.assets_repair r where r.ticket_id = t.id), 0);
  insert into _r (test, expected, result) values ('ticket totals match repairs', '0 mismatches', v_n || ' mismatches');
  select count(*) into v_n from (select 1 from public.assets_tickets_details where assets_id is not null and "Tickets_id" is not null group by assets_id, "Tickets_id" having count(*) > 1) d;
  insert into _r (test, expected, result) values ('duplicate asset links (real pairs)', '0', v_n::text);
  select count(*) into v_n from information_schema.columns where table_schema = 'public' and table_name = 'users' and column_name = 'password';
  insert into _r (test, expected, result) values ('users.password column', '0', v_n::text);
end $$;
select test, expected, result from _r order by n;
