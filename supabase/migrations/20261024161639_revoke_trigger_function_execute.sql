-- Trigger functions are not meant to be called over the API (Supabase
-- advisor 0028/0029). Also included at the end of
-- 20261024161520_notifications_and_hardening.sql for fresh databases.
revoke all on function public.notify_ticket_change() from public, anon, authenticated;
revoke all on function public.notify_location_request_change() from public, anon, authenticated;
revoke all on function public.notify_location_session_change() from public, anon, authenticated;
revoke all on function public.notify_asset_repair() from public, anon, authenticated;
