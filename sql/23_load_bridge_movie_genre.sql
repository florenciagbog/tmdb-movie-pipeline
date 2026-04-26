insert into analytics.bridge_movie_genre (movie_key, genre_id)
select
    t.movie_id as movie_key,
    (jsonb_array_elements_text(t.movie_payload -> 'genre_ids'))::integer as genre_id
from raw.tmdb_trending_movies_raw t
where t.movie_payload ? 'genre_ids' -- Does this JSON object contain this key
on conflict (movie_key, genre_id) do nothing;

