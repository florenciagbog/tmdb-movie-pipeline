-- One row per movie per day with the full movie JSON. Key: (snapshot_date, endpoint, movie_id)
CREATE TABLE IF NOT EXISTS staging.tmdb_movie_entries (
    snapshot_date  DATE      NOT NULL,
    endpoint       STRING    NOT NULL,
    page           INT64     NOT NULL,
    rank_overall   INT64     NOT NULL,
    movie_id       INT64     NOT NULL,
    title          STRING,
    movie_payload  JSON      NOT NULL,
    inserted_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Flattened daily metrics. Key: (snapshot_date, movie_id)
CREATE TABLE IF NOT EXISTS staging.tmdb_daily_metrics (
    snapshot_date  DATE      NOT NULL,
    movie_id       INT64     NOT NULL,
    title          STRING,
    rank_overall   INT64,
    popularity     FLOAT64,
    vote_average   FLOAT64,
    vote_count     INT64,
    inserted_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

-- Best YouTube trailer per movie. Key: movie_id
CREATE TABLE IF NOT EXISTS staging.tmdb_movie_trailers (
    movie_id           INT64     NOT NULL,
    trailer_url        STRING,
    trailer_checked_at TIMESTAMP NOT NULL
);
