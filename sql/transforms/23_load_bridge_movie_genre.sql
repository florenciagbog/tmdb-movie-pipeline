INSERT INTO analytics.bridge_movie_genre (movie_id, genre_id)
SELECT
    t.movie_id AS movie_id,
    (jsonb_array_elements_text(t.movie_payload -> 'genre_ids'))::INTEGER AS genre_id
FROM staging.tmdb_movie_entries t
WHERE t.movie_payload ? 'genre_ids' -- Does this JSON object contain this key
ON CONFLICT (movie_id, genre_id) DO NOTHING;

