-- Removes the plain-text password column from public.users.
--
-- DESTRUCTIVE: deletes the stored password values (4 rows had one on
-- 2026-10-24). Supabase Auth keeps the real (hashed) credentials, and nothing
-- in the app reads this column, so sign-in is not affected. Apply only after
-- explicit approval. There is no rollback for the deleted values; anyone who
-- needs a known password must reset it in Supabase Auth.

begin;
alter table public.users drop column if exists password;
commit;
