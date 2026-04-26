INSERT INTO analytics.dim_movie (
    movie_key,
    title,
    original_title,
    original_language,
    release_date,
    adult,
    overview,
    poster_path
)
SELECT
    movie_id AS movie_key,
    MAX(title) AS title,
    MAX(movie_payload->>'original_title') AS original_title,
    MAX(movie_payload->>'original_language') AS original_language,
    MAX(NULLIF(movie_payload->>'release_date', '')::date) AS release_date,
    BOOL_OR(COALESCE(NULLIF(movie_payload->>'adult', '')::boolean, false)) AS adult,
    MAX(movie_payload->>'overview') AS overview,
    MAX(movie_payload->>'poster_path') AS poster_path
FROM raw.tmdb_trending_movies_raw
WHERE movie_id IS NOT NULL
GROUP BY movie_id
ON CONFLICT (movie_key) DO UPDATE
SET
    title = EXCLUDED.title,
    original_title = EXCLUDED.original_title,
    original_language = EXCLUDED.original_language,
    release_date = EXCLUDED.release_date,
    adult = EXCLUDED.adult,
    overview = EXCLUDED.overview,
    poster_path = EXCLUDED.poster_path;