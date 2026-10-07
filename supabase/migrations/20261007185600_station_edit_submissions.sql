create table if not exists public.station_edit_submissions (
  id uuid primary key default gen_random_uuid(),
  station_id text not null check (length(trim(station_id)) > 0),
  submitted_by uuid references auth.users(id) on delete set null,
  current_name text not null,
  current_address text not null,
  current_charger_count integer
    check (current_charger_count is null or current_charger_count > 0),
  current_connector_types text[] not null default '{}',
  current_operational_status text not null
    check (current_operational_status in ('operational', 'unavailable', 'unknown')),
  suggested_name text not null check (length(trim(suggested_name)) > 0),
  suggested_address text not null check (length(trim(suggested_address)) > 0),
  suggested_charger_count integer not null check (suggested_charger_count > 0),
  suggested_connector_types text[] not null
    check (cardinality(suggested_connector_types) > 0),
  suggested_operational_status text not null
    check (suggested_operational_status in ('operational', 'unavailable')),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  admin_notes text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null
);

create index if not exists station_edit_submissions_owner_created_idx
  on public.station_edit_submissions (submitted_by, created_at desc);
create index if not exists station_edit_submissions_status_created_idx
  on public.station_edit_submissions (status, created_at desc);
create index if not exists station_edit_submissions_station_idx
  on public.station_edit_submissions (station_id);

alter table public.station_edit_submissions enable row level security;

revoke all on public.station_edit_submissions from anon, authenticated;
grant select on public.station_edit_submissions to authenticated;
grant insert (
  station_id,
  submitted_by,
  current_name,
  current_address,
  current_charger_count,
  current_connector_types,
  current_operational_status,
  suggested_name,
  suggested_address,
  suggested_charger_count,
  suggested_connector_types,
  suggested_operational_status
) on public.station_edit_submissions to authenticated;
grant all on public.station_edit_submissions to service_role;

drop policy if exists "Users can submit their own station edits"
  on public.station_edit_submissions;
create policy "Users can submit their own station edits"
  on public.station_edit_submissions
  for insert
  to authenticated
  with check (
    submitted_by = (select auth.uid())
    and status = 'pending'
    and admin_notes is null
    and reviewed_at is null
    and reviewed_by is null
  );

drop policy if exists "Users can view their own station edits"
  on public.station_edit_submissions;
create policy "Users can view their own station edits"
  on public.station_edit_submissions
  for select
  to authenticated
  using (submitted_by = (select auth.uid()));

create or replace function public.review_station_edit(
  p_edit_id uuid,
  p_reviewer_id uuid,
  p_decision text,
  p_admin_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  edit public.station_edit_submissions%rowtype;
begin
  if auth.role() is distinct from 'service_role' then
    raise exception 'Only the trusted admin service can review station edits';
  end if;
  if p_reviewer_id is null then
    raise exception 'Reviewer identity is required';
  end if;
  if p_decision is null or p_decision not in ('approved', 'rejected') then
    raise exception 'Decision must be approved or rejected';
  end if;

  select *
    into edit
    from public.station_edit_submissions
    where id = p_edit_id
    for update;

  if not found then
    raise exception 'Station edit not found';
  end if;
  if edit.status <> 'pending' then
    raise exception 'Only pending station edits can be reviewed';
  end if;

  if p_decision = 'approved' then
    if edit.station_id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      raise exception 'This station is not managed in the public stations table';
    end if;

    update public.stations
      set name = edit.suggested_name,
          address = edit.suggested_address,
          charger_count = edit.suggested_charger_count,
          connector_types = edit.suggested_connector_types,
          operational_status = edit.suggested_operational_status,
          updated_at = now()
      where id = edit.station_id::uuid;

    if not found then
      raise exception 'The public station record no longer exists';
    end if;
  end if;

  update public.station_edit_submissions
    set status = p_decision,
        admin_notes = p_admin_notes,
        reviewed_at = now(),
        reviewed_by = p_reviewer_id
    where id = p_edit_id;
end;
$$;

revoke all on function public.review_station_edit(uuid, uuid, text, text)
  from public, anon, authenticated;
grant execute on function public.review_station_edit(uuid, uuid, text, text)
  to service_role;
