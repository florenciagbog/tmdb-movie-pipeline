-- create the table that will hold API responses
CREATE TABLE raw.tmdb_trending_raw (
     id SERIAL PRIMARY KEY,
     snapshot_date DATE NOT NULL,
     endpoint TEXT NOT NULL,
     payload JSONB NOT NULL,
     inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
 );





-- -- Changing Audit column to include Timezone:


-- alter table raw.tmdb_trending_raw 
-- alter column inserted_at type timestamptz using inserted_at::timestamptz; 


-- alter table raw.tmdb_trending_raw 
-- alter column inserted_at set default now(); 


-- alter table raw.tmdb_trending_raw 
-- alter column inserted_at set not null;



-- select column_name, data_type
-- from information_schema.columns
-- where table_schema = 'raw'
--   and table_name = 'tmdb_trending_raw';




alter table raw.tmdb_trending_movies_raw
alter column inserted_at type timestamptz using inserted_at::timestamptz,
alter column inserted_at set default now(),
alter column inserted_at set not null;

alter table raw.tmdb_trending_daily
add column inserted_at timestamptz default now();

alter table analytics.fact_trending_daily
add column inserted_at timestamptz default now();