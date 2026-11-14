CREATE TABLE IF NOT EXISTS analytics.dim_calendar (
    date_key       INT64  NOT NULL,
    full_date      DATE   NOT NULL,
    day_number     INT64  NOT NULL,
    month_number   INT64  NOT NULL,
    month_name     STRING NOT NULL,
    quarter_number INT64  NOT NULL,
    year_number    INT64  NOT NULL,
    week_number    INT64  NOT NULL,
    day_name       STRING NOT NULL,
    is_weekend     BOOL   NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.dim_movie (
    movie_id          INT64     NOT NULL,
    title             STRING,
    original_title    STRING,
    original_language STRING,
    language_name     STRING,
    release_date      DATE,
    adult             BOOL,
    overview          STRING,
    poster_path       STRING,
    trailer_url       STRING,
    inserted_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS analytics.dim_genre (
    genre_id   INT64 NOT NULL,
    genre_name STRING
);

CREATE TABLE IF NOT EXISTS analytics.dim_language (
    language_code STRING NOT NULL,
    language_name STRING
);

CREATE TABLE IF NOT EXISTS analytics.bridge_movie_genre (
    movie_id INT64 NOT NULL,
    genre_id INT64 NOT NULL
);

CREATE TABLE IF NOT EXISTS analytics.fact_daily_movie (
    snapshot_date_key INT64     NOT NULL,
    movie_id          INT64     NOT NULL,
    rank              INT64,
    popularity        NUMERIC,
    vote_average      NUMERIC,
    vote_count        INT64,
    previous_rank     INT64,
    rank_change       INT64,
    is_new_entry      BOOL,
    inserted_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
);

CREATE TABLE IF NOT EXISTS analytics.dim_snapshot (
    snapshot_date_key INT64 NOT NULL,
    snapshot_date     DATE  NOT NULL,
    is_latest         BOOL  NOT NULL
);
