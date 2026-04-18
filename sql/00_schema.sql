-- create schema
CREATE SCHEMA IF NOT EXISTS raw;

-- create the table that will hold API responses
CREATE TABLE IF NOT EXISTS raw.tmdb_trending_raw (
     id SERIAL PRIMARY KEY,
     snapshot_date DATE NOT NULL,
     endpoint TEXT NOT NULL,
     payload JSONB NOT NULL,
     page INT NOT NULL,
     inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ensure no duplicate pages per day
ALTER TABLE raw.tmdb_trending_raw
ADD CONSTRAINT unique_snapshot_page
UNIQUE (snapshot_date, page);