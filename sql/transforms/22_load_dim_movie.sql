INSERT INTO analytics.dim_movie (
    movie_id,
    title,
    original_title,
    original_language,
    release_date,
    adult,
    overview,
    poster_path
)
WITH latest AS (
    SELECT DISTINCT ON (movie_id)
        movie_id,
        title,
        movie_payload
    FROM staging.tmdb_movie_entries
    WHERE movie_id IS NOT NULL
    ORDER BY movie_id, snapshot_date DESC
)
SELECT
    movie_id                                                    AS movie_id,
    title,
    movie_payload->>'original_title'                           AS original_title,
    movie_payload->>'original_language'                        AS original_language,
    NULLIF(movie_payload->>'release_date', '')::date           AS release_date,
    COALESCE(NULLIF(movie_payload->>'adult', '')::boolean, false) AS adult,
    movie_payload->>'overview'                                 AS overview,
    movie_payload->>'poster_path'                              AS poster_path
FROM latest
ON CONFLICT (movie_id) DO UPDATE
SET
    title             = EXCLUDED.title,
    original_title    = EXCLUDED.original_title,
    original_language = EXCLUDED.original_language,
    release_date      = EXCLUDED.release_date,
    adult             = EXCLUDED.adult,
    overview          = EXCLUDED.overview,
    poster_path       = EXCLUDED.poster_path;