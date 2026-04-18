insert into analytics.dim_calendar (
    date_key,
    full_date,
    day_number,
    month_number,
    month_name,
    quarter_number,
    year_number,
    week_number,
    day_name,
    is_weekend
)
select distinct
    to_char(snapshot_date, 'YYYYMMDD')::integer as date_key,
    snapshot_date as full_date,
    extract(day from snapshot_date)::integer as day_number,
    extract(month from snapshot_date)::integer as month_number,
    trim(to_char(snapshot_date, 'Month')) as month_name,
    extract(quarter from snapshot_date)::integer as quarter_number,
    extract(year from snapshot_date)::integer as year_number,
    extract(week from snapshot_date)::integer as week_number,
    trim(to_char(snapshot_date, 'Day')) as day_name,
    case
        when extract(isodow from snapshot_date) in (6, 7) then true
        else false
    end as is_weekend
from raw.tmdb_trending_daily
where snapshot_date is not null
on conflict (date_key) do nothing;