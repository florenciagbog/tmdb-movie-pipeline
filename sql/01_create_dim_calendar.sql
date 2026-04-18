create table if not exists analytics.dim_calendar (
    date_key integer primary key,
    full_date date not null unique,
    day_number integer not null,
    month_number integer not null,
    month_name text not null,
    quarter_number integer not null,
    year_number integer not null,
    week_number integer not null,
    day_name text not null,
    is_weekend boolean not null
);