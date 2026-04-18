# TMDB Movie Trending Data Pipeline

## Overview
This project implements a batch data pipeline that ingests daily trending movie data 
from the TMDB API, stores raw JSON payloads in PostgreSQL, transforms nested structures 
into relational tables using SQL, and exposes analytics-ready datasets for reporting in Power BI.

## Architecture
TMDB API (trending + genres)
 ↓
Python ingestion scripts (ingest_tmdb.py, get_tmdb_genres.py)
 ↓
PostgreSQL raw layer (raw JSON storage)
 ↓
SQL transformations (flattening, deduplication)
 ↓
Star schema (facts + dimensions)
 ↓
Power BI dashboard (in progress)

## Tech Stack
- Python
- PostgreSQL
- SQL
- TMDB API
- Power BI

## Database Structure

**Raw layer**
- `raw.tmdb_trending_raw` — raw JSON payloads from the API
- `raw.tmdb_trending_movies_raw` — one row per movie per day, flattened
- `raw.tmdb_trending_daily` — cleaned daily rankings

**Analytics layer**
- `analytics.fact_trending_daily` — daily ranking fact table with rank change metrics
- `analytics.dim_movie` — movie dimension
- `analytics.dim_genre` — genre lookup
- `analytics.dim_calendar` — calendar dimension
- `analytics.bridge_movie_genre` — movie to genre relationship

## Pipeline Features
- Daily ingestion of trending movies and genre data
- Raw JSON storage for full traceability
- Idempotent loads using ON CONFLICT throughout
- Automatic backfill of missed days
- Rank change tracking (previous rank, rank delta, new entry detection)

## Power BI Dashboard (in progress)
- Top trending movies of the day
- Ranking trends over time
- Best movies by popularity and vote average