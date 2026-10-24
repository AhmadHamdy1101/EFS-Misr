-- One link per (asset, ticket).
--
-- Stops the app from linking the same asset to the same ticket twice (the
-- app also checks before inserting).
--
-- Dry run on 2026-10-25: the 5 "duplicate" groups seen in the live table are
-- 34 orphaned rows whose ticket was deleted ("Tickets_id" set to NULL), not
-- real duplicates; NULLs never conflict in a unique index, so they stay.
-- The delete below therefore removes 0 rows today; it only guards against
-- real duplicates appearing before this runs (approved 2026-10-25), keeping
-- the oldest row of each pair.

begin;

delete from public.assets_tickets_details d
using public.assets_tickets_details k
where d.assets_id = k.assets_id
  and d."Tickets_id" = k."Tickets_id"
  and d.id > k.id;

create unique index if not exists assets_tickets_details_pair_key
  on public.assets_tickets_details (assets_id, "Tickets_id");

commit;
