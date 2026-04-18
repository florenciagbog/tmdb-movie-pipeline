alter table analytics.dim_movie
add column if not exists original_title text,
add column if not exists original_language text,
add column if not exists release_date date,
add column if not exists adult boolean,
add column if not exists overview text;