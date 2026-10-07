create table if not exists public.station_submissions (
  id uuid primary key default gen_random_uuid(),
  submitted_by uuid references auth.users(id) on delete set null,
  name text not null check (length(trim(name)) > 0),
  operator_name text,
  address text,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  connector_types text[] not null default '{}',
  charger_count integer not null default 1 check (charger_count > 0),
  power_kw double precision check (power_kw is null or power_kw > 0),
  notes text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  admin_notes text,
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid references auth.users(id) on delete set null
);

create index if not exists station_submissions_owner_created_idx
  on public.station_submissions (submitted_by, created_at desc);
create index if not exists station_submissions_status_created_idx
  on public.station_submissions (status, created_at desc);

alter table public.station_submissions enable row level security;

revoke all on public.station_submissions from anon, authenticated;
grant select, insert on public.station_submissions to authenticated;
grant all on public.station_submissions to service_role;

create policy "Users can create their own pending submissions"
  on public.station_submissions
  for insert
  to authenticated
  with check (
    submitted_by = (select auth.uid())
    and status = 'pending'
    and admin_notes is null
    and reviewed_at is null
    and reviewed_by is null
  );

create policy "Users can view their own submissions"
  on public.station_submissions
  for select
  to authenticated
  using (submitted_by = (select auth.uid()));

create table if not exists public.stations (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null unique
    references public.station_submissions(id) on delete restrict,
  name text not null check (length(trim(name)) > 0),
  operator_name text,
  address text,
  latitude double precision not null check (latitude between -90 and 90),
  longitude double precision not null check (longitude between -180 and 180),
  connector_types text[] not null default '{}',
  charger_count integer not null default 1 check (charger_count > 0),
  power_kw double precision check (power_kw is null or power_kw > 0),
  notes text,
  operational_status text not null default 'unknown'
    check (operational_status in ('operational', 'unavailable', 'unknown')),
  source text not null default 'user' check (source = 'user'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists stations_latitude_longitude_idx
  on public.stations (latitude, longitude);

create or replace function public.require_approved_station_submission()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (
    select 1
    from public.station_submissions
    where id = new.submission_id
      and status = 'approved'
  ) then
    raise exception 'Only approved submissions can become public stations';
  end if;
  return new;
end;
$$;

revoke all on function public.require_approved_station_submission()
  from public, anon, authenticated;

drop trigger if exists stations_require_approved_submission
  on public.stations;
create trigger stations_require_approved_submission
  before insert or update of submission_id on public.stations
  for each row execute function public.require_approved_station_submission();

create or replace function public.remove_unapproved_public_station()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status <> 'approved' then
    delete from public.stations where submission_id = new.id;
  end if;
  return new;
end;
$$;

revoke all on function public.remove_unapproved_public_station()
  from public, anon, authenticated;

drop trigger if exists station_submissions_hide_unapproved_station
  on public.station_submissions;
create trigger station_submissions_hide_unapproved_station
  after update of status on public.station_submissions
  for each row execute function public.remove_unapproved_public_station();

alter table public.stations enable row level security;

revoke all on public.stations from anon, authenticated;
grant select on public.stations to anon, authenticated;
grant all on public.stations to service_role;

create policy "Anyone can read approved public stations"
  on public.stations
  for select
  to anon, authenticated
  using (true);
