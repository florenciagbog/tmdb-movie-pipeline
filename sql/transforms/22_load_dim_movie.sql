INSERT INTO analytics.dim_movie (
    movie_id,
    title,
    original_title,
    original_language,
    language_name,
    release_date,
    adult,
    overview,
    poster_path,
    trailer_url
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
    l.movie_id                                                   AS movie_id,
    l.title,
    l.movie_payload->>'original_title'                           AS original_title,
    l.movie_payload->>'original_language'                        AS original_language,
    COALESCE(dl.language_name, l.movie_payload->>'original_language') AS language_name,
    NULLIF(l.movie_payload->>'release_date', '')::date           AS release_date,
    COALESCE(NULLIF(l.movie_payload->>'adult', '')::boolean, false) AS adult,
    l.movie_payload->>'overview'                                 AS overview,
    l.movie_payload->>'poster_path'                              AS poster_path,
    t.trailer_url                                                AS trailer_url
FROM latest l
LEFT JOIN analytics.dim_language dl
    ON dl.language_code = l.movie_payload->>'original_language'
LEFT JOIN staging.tmdb_movie_trailers t
    ON t.movie_id = l.movie_id
ON CONFLICT (movie_id) DO UPDATE
SET
    title             = EXCLUDED.title,
    original_title    = EXCLUDED.original_title,
    original_language = EXCLUDED.original_language,
    language_name     = EXCLUDED.language_name,
    release_date      = EXCLUDED.release_date,
    adult             = EXCLUDED.adult,
    overview          = EXCLUDED.overview,
    poster_path       = EXCLUDED.poster_path,
    trailer_url       = EXCLUDED.trailer_url;


