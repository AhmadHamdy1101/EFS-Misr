-- Rollback reference: the tracking functions and policies as they were in the
-- live database (project cxjgprvhjrjbmrazvrsa) on 2026-10-24, before
-- 20261024161406_live_location_tracking.sql. To roll back, drop the new
-- signatures and run this file. NOTE: these versions contain the NULL-role
-- authorization bypass described in that migration.

CREATE OR REPLACE FUNCTION private.tracking_role(p_user uuid)
 RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO ''
AS $function$
  SELECT role FROM public.tracking_members WHERE user_id=p_user AND enabled=true;
$function$;

CREATE OR REPLACE FUNCTION public.tracking_cancel_request(p_request uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
BEGIN
 IF auth.uid() IS NULL OR private.tracking_role(auth.uid()) <> 'admin' THEN RAISE EXCEPTION 'Not authorized'; END IF;
 UPDATE public.location_requests SET status='cancelled',responded_at=now()
 WHERE id=p_request AND admin_id=auth.uid() AND status='pending';
 IF NOT FOUND THEN RAISE EXCEPTION 'Request not cancellable'; END IF;
END $function$;

CREATE OR REPLACE FUNCTION public.tracking_request_location(p_worker uuid)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE v_id uuid; v_actor uuid := auth.uid();
BEGIN
 IF v_actor IS NULL OR private.tracking_role(v_actor) <> 'admin' THEN RAISE EXCEPTION 'Not authorized'; END IF;
 IF private.tracking_role(p_worker) <> 'worker' THEN RAISE EXCEPTION 'Not an enabled worker'; END IF;
 UPDATE public.location_requests SET status='expired', responded_at=now() WHERE worker_id=p_worker AND status='pending' AND expires_at <= now();
 INSERT INTO public.location_requests(admin_id,worker_id) VALUES(v_actor,p_worker) RETURNING id INTO v_id;
 RETURN v_id;
END $function$;

CREATE OR REPLACE FUNCTION public.tracking_respond_request(p_request uuid, p_accept boolean)
 RETURNS text LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE v_row public.location_requests%ROWTYPE;
BEGIN
 IF auth.uid() IS NULL OR private.tracking_role(auth.uid()) <> 'worker' THEN RAISE EXCEPTION 'Not authorized'; END IF;
 SELECT * INTO v_row FROM public.location_requests WHERE id=p_request FOR UPDATE;
 IF NOT FOUND OR v_row.worker_id<>auth.uid() OR v_row.status<>'pending' THEN RAISE EXCEPTION 'Invalid request'; END IF;
 IF v_row.expires_at<=now() THEN
   UPDATE public.location_requests SET status='expired',responded_at=now() WHERE id=p_request;
   RETURN 'expired';
 END IF;
 UPDATE public.location_requests SET status=CASE WHEN p_accept THEN 'accepted' ELSE 'declined' END,responded_at=now() WHERE id=p_request;
 RETURN CASE WHEN p_accept THEN 'accepted' ELSE 'declined' END;
END $function$;

CREATE OR REPLACE FUNCTION public.tracking_start_session(p_request uuid DEFAULT NULL::uuid)
 RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE v_id uuid; v_actor uuid:=auth.uid(); v_row public.location_requests%ROWTYPE;
BEGIN
 IF v_actor IS NULL OR private.tracking_role(v_actor)<>'worker' THEN RAISE EXCEPTION 'Not authorized'; END IF;
 PERFORM 1 FROM public.tracking_members WHERE user_id=v_actor FOR UPDATE;
 IF p_request IS NOT NULL THEN
   SELECT * INTO v_row FROM public.location_requests WHERE id=p_request FOR UPDATE;
   IF NOT FOUND OR v_row.worker_id<>v_actor OR v_row.status<>'accepted' THEN RAISE EXCEPTION 'Request not accepted by this worker'; END IF;
   IF v_row.expires_at <= v_row.responded_at THEN RAISE EXCEPTION 'Expired approval'; END IF;
 END IF;
 INSERT INTO public.location_sessions(worker_id,request_id,source)
 VALUES(v_actor,p_request,CASE WHEN p_request IS NULL THEN 'worker' ELSE 'admin_request' END)
 RETURNING id INTO v_id;
 RETURN v_id;
END $function$;

CREATE OR REPLACE FUNCTION public.tracking_stop_session(p_session uuid)
 RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE v_actor uuid:=auth.uid();
BEGIN
 IF v_actor IS NULL OR private.tracking_role(v_actor)<>'worker' THEN RAISE EXCEPTION 'Not authorized'; END IF;
 PERFORM 1 FROM public.location_sessions WHERE id=p_session AND worker_id=v_actor AND status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'No active session'; END IF;
 UPDATE public.location_sessions SET status='stopped',ended_at=now() WHERE id=p_session;
 DELETE FROM public.worker_locations WHERE worker_id=v_actor AND session_id=p_session;
END $function$;

CREATE OR REPLACE FUNCTION public.tracking_update_location(p_session uuid, p_lat double precision, p_lng double precision, p_accuracy double precision DEFAULT NULL::double precision, p_recorded_at timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO ''
AS $function$
DECLARE v_actor uuid:=auth.uid(); v_time timestamptz:=COALESCE(p_recorded_at,now());
BEGIN
 IF v_actor IS NULL OR private.tracking_role(v_actor)<>'worker' THEN RAISE EXCEPTION 'Not authorized'; END IF;
 IF p_lat IS NULL OR p_lng IS NULL OR NOT (p_lat BETWEEN -90 AND 90) OR NOT (p_lng BETWEEN -180 AND 180)
    OR (p_accuracy IS NOT NULL AND (p_accuracy < 0 OR NOT isfinite(p_accuracy)))
    OR NOT isfinite(p_lat) OR NOT isfinite(p_lng) THEN RAISE EXCEPTION 'Invalid coordinates'; END IF;
 IF v_time > now()+interval '30 seconds' OR v_time < now()-interval '2 minutes' THEN RAISE EXCEPTION 'Stale or future timestamp'; END IF;
 PERFORM 1 FROM public.location_sessions WHERE id=p_session AND worker_id=v_actor AND status='active' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'No active session'; END IF;
 INSERT INTO public.worker_locations(worker_id,session_id,latitude,longitude,accuracy_meters,recorded_at,received_at)
 VALUES(v_actor,p_session,p_lat,p_lng,p_accuracy,v_time,now())
 ON CONFLICT(worker_id) DO UPDATE SET
 session_id=EXCLUDED.session_id,latitude=EXCLUDED.latitude,longitude=EXCLUDED.longitude,
 accuracy_meters=EXCLUDED.accuracy_meters,recorded_at=EXCLUDED.recorded_at,received_at=now()
 WHERE public.worker_locations.session_id<>EXCLUDED.session_id OR public.worker_locations.recorded_at<EXCLUDED.recorded_at;
 RETURN FOUND;
END $function$;

-- Policies before the change:
--   tracking_members_self   SELECT authenticated  user_id = auth.uid()
--   tracking_requests_read  SELECT authenticated  worker_id = auth.uid() OR (admin_id = auth.uid() AND tracking_role = 'admin')
--   tracking_sessions_read  SELECT authenticated  worker_id = auth.uid() OR tracking_role = 'admin'
--   tracking_locations_read SELECT authenticated  worker_id = auth.uid() OR tracking_role = 'admin'
