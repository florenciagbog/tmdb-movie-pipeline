insert into analytics.dim_movie (
    movie_key,
    title,
    original_title,
    original_language,
    release_date,
    adult,
    overview
)
select
    movie_id as movie_key,
    max(title) as title,
    max(movie_payload ->> 'original_title') as original_title,
    max(movie_payload ->> 'original_language') as original_language,
    max(nullif(movie_payload ->> 'release_date', '')::date) as release_date,
    bool_or(coalesce(nullif(movie_payload ->> 'adult', '')::boolean, false)) as adult,
    max(movie_payload ->> 'overview') as overview
from raw.tmdb_trending_movies_raw
where movie_id is not null
group by movie_id
on conflict (movie_key) do update
set
    title = excluded.title,
    original_title = excluded.original_title,
    original_language = excluded.original_language,
    release_date = excluded.release_date,
    adult = excluded.adult,
    overview = excluded.overview;