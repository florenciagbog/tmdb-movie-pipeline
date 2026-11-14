CREATE TABLE IF NOT EXISTS analytics.fact_daily_movie (
    snapshot_date_key  INTEGER      NOT NULL,
    movie_id          INTEGER      NOT NULL,
    rank               INTEGER,
    popularity         NUMERIC(12,4),
    vote_average       NUMERIC(5,2),
    vote_count         INTEGER,
    previous_rank      INTEGER,
    rank_change        INTEGER,
    is_new_entry       BOOLEAN,
    inserted_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
    PRIMARY KEY (snapshot_date_key, movie_key),
    FOREIGN KEY (snapshot_date_key) REFERENCES analytics.dim_calendar(date_key),
    FOREIGN KEY (movie_key)         REFERENCES analytics.dim_movie(movie_key)
);



--ALTER TABLE analytics.fact_trending_daily RENAME COLUMN movie_key TO movie_id;