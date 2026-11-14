-- Raw TMDB trending responses: one row per page per day.
-- Logical key: (snapshot_date, page) — enforced by the ingestion query.
CREATE TABLE IF NOT EXISTS raw.tmdb_api_responses (
    snapshot_date DATE      NOT NULL,
    endpoint      STRING    NOT NULL,
    page          INT64     NOT NULL,
    payload       JSON      NOT NULL,
    inserted_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Raw TMDB /movie/{id}/videos responses. Logical key: (movie_id, fetched_at).
CREATE TABLE IF NOT EXISTS raw.tmdb_movie_videos (
    movie_id   INT64     NOT NULL,
    fetched_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
    payload    JSON      NOT NULL
);
