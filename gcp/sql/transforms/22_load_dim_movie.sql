MERGE analytics.dim_movie t
USING (
    SELECT
        l.movie_id,
        l.title,
        JSON_VALUE(l.movie_payload, '$.original_title')                       AS original_title,
        JSON_VALUE(l.movie_payload, '$.original_language')                    AS original_language,
        COALESCE(dl.language_name,
                 JSON_VALUE(l.movie_payload, '$.original_language'))          AS language_name,
        SAFE_CAST(NULLIF(JSON_VALUE(l.movie_payload, '$.release_date'), '') AS DATE) AS release_date,
        COALESCE(LAX_BOOL(l.movie_payload.adult), FALSE)                      AS adult,
        JSON_VALUE(l.movie_payload, '$.overview')                             AS overview,
        JSON_VALUE(l.movie_payload, '$.poster_path')                          AS poster_path,
        tr.trailer_url
    FROM (
        SELECT movie_id, title, movie_payload
        FROM staging.tmdb_movie_entries
        WHERE movie_id IS NOT NULL
        QUALIFY ROW_NUMBER() OVER (PARTITION BY movie_id ORDER BY snapshot_date DESC) = 1
    ) l
    LEFT JOIN analytics.dim_language dl
        ON dl.language_code = JSON_VALUE(l.movie_payload, '$.original_language')
    LEFT JOIN staging.tmdb_movie_trailers tr
        ON tr.movie_id = l.movie_id
) s
ON t.movie_id = s.movie_id
WHEN MATCHED THEN UPDATE SET
    title             = s.title,
    original_title    = s.original_title,
    original_language = s.original_language,
    language_name     = s.language_name,
    release_date      = s.release_date,
    adult             = s.adult,
    overview          = s.overview,
    poster_path       = s.poster_path,
    trailer_url       = s.trailer_url
WHEN NOT MATCHED THEN
    INSERT (movie_id, title, original_title, original_language, language_name,
            release_date, adult, overview, poster_path, trailer_url)
    VALUES (s.movie_id, s.title, s.original_title, s.original_language, s.language_name,
            s.release_date, s.adult, s.overview, s.poster_path, s.trailer_url);
