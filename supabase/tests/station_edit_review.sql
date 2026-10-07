begin;

select plan(9);

insert into auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  raw_app_meta_data,
  raw_user_meta_data,
  created_at,
  updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  '10000000-0000-0000-0000-000000000001',
  'authenticated',
  'authenticated',
  'station-edit-review-test@example.invalid',
  '',
  now(),
  '{}',
  '{}',
  now(),
  now()
);

insert into public.station_submissions (
  id, name, latitude, longitude, charger_count, status
) values
  (
    '20000000-0000-0000-0000-000000000001',
    'Original',
    19.07,
    72.87,
    2,
    'approved'
  ),
  (
    '20000000-0000-0000-0000-000000000002',
    'Rejected Original',
    19.08,
    72.88,
    1,
    'approved'
  );

insert into public.stations (
  id,
  submission_id,
  name,
  operator_name,
  address,
  latitude,
  longitude,
  connector_types,
  charger_count,
  operational_status,
  source,
  notes,
  created_at
) values
  (
    '30000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    'Original',
    'Original Operator',
    'Original Address',
    19.07,
    72.87,
    array['CCS2'],
    2,
    'unavailable',
    'user',
    'System note',
    '2026-10-07T12:00:00Z'
  ),
  (
    '30000000-0000-0000-0000-000000000002',
    '20000000-0000-0000-0000-000000000002',
    'Rejected Original',
    'Keep Operator',
    'Rejected Address',
    19.08,
    72.88,
    array['Type 2'],
    1,
    'operational',
    'user',
    'Keep this note',
    '2026-10-07T12:00:00Z'
  );

insert into public.station_edit_submissions (
  id,
  station_id,
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
) values
  (
    '40000000-0000-0000-0000-000000000001',
    '30000000-0000-0000-0000-000000000001',
    'Original',
    'Original Address',
    2,
    array['CCS2'],
    'unavailable',
    'Corrected Name',
    'Corrected Address',
    4,
    array['CCS2', 'Type 2'],
    'operational'
  ),
  (
    '40000000-0000-0000-0000-000000000002',
    '30000000-0000-0000-0000-000000000002',
    'Rejected Original',
    'Rejected Address',
    1,
    array['Type 2'],
    'operational',
    'Must Not Apply',
    'Must Not Apply',
    5,
    array['CCS'],
    'unavailable'
  );

select set_config('request.jwt.claim.role', 'service_role', true);

select public.review_station_edit(
  '40000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-000000000001',
  'approved'
);

select is(
  (select name from public.stations where id = '30000000-0000-0000-0000-000000000001'),
  'Corrected Name',
  'approval applies suggested station name'
);
select is(
  (select address from public.stations where id = '30000000-0000-0000-0000-000000000001'),
  'Corrected Address',
  'approval applies suggested address'
);
select is(
  (select charger_count from public.stations where id = '30000000-0000-0000-0000-000000000001'),
  4,
  'approval applies suggested charger count'
);
select is(
  (select connector_types from public.stations where id = '30000000-0000-0000-0000-000000000001'),
  array['CCS2', 'Type 2'],
  'approval applies suggested connector types'
);
select is(
  (select operational_status from public.stations where id = '30000000-0000-0000-0000-000000000001'),
  'operational',
  'approval applies suggested operational status'
);
select is(
  (
    select jsonb_build_object(
      'id', id,
      'submission_id', submission_id,
      'operator_name', operator_name,
      'latitude', latitude,
      'longitude', longitude,
      'source', source,
      'notes', notes,
      'created_at', created_at
    )
    from public.stations
    where id = '30000000-0000-0000-0000-000000000001'
  ),
  jsonb_build_object(
    'id', '30000000-0000-0000-0000-000000000001'::uuid,
    'submission_id', '20000000-0000-0000-0000-000000000001'::uuid,
    'operator_name', 'Original Operator',
    'latitude', 19.07,
    'longitude', 72.87,
    'source', 'user',
    'notes', 'System note',
    'created_at', '2026-10-07T12:00:00Z'::timestamptz
  ),
  'approval preserves station identity and system-controlled data'
);
select is(
  (select status from public.station_edit_submissions where id = '40000000-0000-0000-0000-000000000001'),
  'approved',
  'approval records the edit review status'
);

select public.review_station_edit(
  '40000000-0000-0000-0000-000000000002',
  '10000000-0000-0000-0000-000000000001',
  'rejected',
  'Rejected for test'
);

select is(
  (
    select jsonb_build_object(
      'id', id,
      'name', name,
      'address', address,
      'charger_count', charger_count,
      'connector_types', connector_types,
      'operational_status', operational_status,
      'operator_name', operator_name,
      'latitude', latitude,
      'longitude', longitude,
      'source', source,
      'notes', notes
    )
    from public.stations
    where id = '30000000-0000-0000-0000-000000000002'
  ),
  jsonb_build_object(
    'id', '30000000-0000-0000-0000-000000000002'::uuid,
    'name', 'Rejected Original',
    'address', 'Rejected Address',
    'charger_count', 1,
    'connector_types', array['Type 2'],
    'operational_status', 'operational',
    'operator_name', 'Keep Operator',
    'latitude', 19.08,
    'longitude', 72.88,
    'source', 'user',
    'notes', 'Keep this note'
  ),
  'rejection leaves the public station unchanged'
);
select is(
  (select status from public.station_edit_submissions where id = '40000000-0000-0000-0000-000000000002'),
  'rejected',
  'rejection records the edit review status'
);

select * from finish();
rollback;
