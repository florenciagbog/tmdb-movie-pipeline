CREATE TABLE IF NOT EXISTS analytics.dim_movie (
    movie_id          INTEGER      NOT NULL PRIMARY KEY,
    title              TEXT,
    original_title     TEXT,
    original_language  TEXT,
    release_date       DATE,
    adult              BOOLEAN,
    overview           TEXT,
    poster_path        TEXT,
    inserted_at        TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

-- ALTER TABLE analytics.dim_movie RENAME COLUMN movie_key TO movie_id;