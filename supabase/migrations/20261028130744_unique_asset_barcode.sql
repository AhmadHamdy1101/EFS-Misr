-- One asset per label code (2026-10-28).
--
-- The QR/barcode label holds assets.barcode; the app resolves a scan with
-- an exact match. Duplicate codes would make a scan ambiguous, so the app
-- now refuses them, and this index makes the database refuse them too.
--
-- Applied 2026-10-28 (0 duplicates at the time). Safe to re-run: if duplicates exist it stops with the
-- list of codes and changes nothing; fix those assets first (an admin
-- decision: which asset keeps the code), then run it again.
--
-- Find duplicates beforehand (read-only):
--   select barcode, count(*), array_agg(id order by id)
--   from public.assets where barcode is not null
--   group by barcode having count(*) > 1;

do $$
declare
  dupes text;
begin
  select string_agg(format('%s (%s)', barcode, n), ', ')
    into dupes
  from (
    select barcode, count(*) n
    from public.assets
    where barcode is not null
    group by barcode
    having count(*) > 1
  ) d;
  if dupes is not null then
    raise exception 'Duplicate asset barcodes, fix first: %', dupes;
  end if;
end $$;

create unique index if not exists assets_barcode_unique
  on public.assets (barcode) where barcode is not null;
