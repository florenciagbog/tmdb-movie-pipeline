# TMDB Movie Trending Data Pipeline

## Overview
This project implements a batch data pipeline that ingests daily trending movie data 
from the TMDB API, stores raw JSON payloads in PostgreSQL, transforms nested structures 
into relational tables using SQL, and exposes analytics-ready datasets for reporting in Power BI.

## Architecture
```
TMDB API (trending + genres)
↓
Python ingestion scripts (ingest_tmdb.py, get_tmdb_genres.py)
↓
PostgreSQL raw layer (raw JSON storage)
↓
SQL transformations (flattening, deduplication)
↓
Analytics layer (facts + dimensions)
↓
Power BI dashboard (in progress)
```
## Tech Stack
- Python
- PostgreSQL
- SQL
- TMDB API
- Power BI

## Database Structure

**Raw layer**
- `raw.tmdb_trending_raw` — raw JSON payloads from the TMDB API, one row per page per day
- `raw.tmdb_trending_movies_raw` — flattened movies, one row per movie per day with full JSON payload
- `raw.tmdb_trending_daily` — cleaned daily rankings with numeric metrics extracted from JSON

**Analytics layer**
- `analytics.fact_trending_daily` — daily fact table with rank, engagement metrics, and rank change tracking
- `analytics.dim_movie` — movie attributes (title, language, release date, overview)
- `analytics.dim_genre` — genre reference table
- `analytics.dim_calendar` — calendar dimension for date-based filtering and reporting
- `analytics.bridge_movie_genre` — many-to-many relationship between movies and genres

## Pipeline Features
- Daily ingestion of trending movies and genre data
- Raw JSON storage for full traceability
- Idempotent loads using ON CONFLICT throughout
- Rank change tracking (previous rank, rank delta, new entry detection)

## Power BI Dashboard (in progress)
