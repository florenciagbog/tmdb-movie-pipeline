create table analytics.dim_genre ( gendre_id integer primary key,
genre_name text);

alter table analytics.dim_genre 
RENAME column gendre_id to genre_id;