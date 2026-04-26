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
- `raw.tmdb_api_responses` — raw JSON payloads from the TMDB API, one row per page per day

**Staging layer**
- `staging.tmdb_movie_entries` — flattened movies, one row per movie per day with full JSON payload
- `staging.tmdb_daily_metrics` — cleaned daily rankings with numeric metrics extracted from JSON

**Analytics layer**
- `analytics.fact_daily_movie` — daily fact table with rank, engagement metrics, and rank change tracking
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
- Top trending movies of the day
- Ranking trends over time
- Best movies by popularity and vote average

## Future Improvements
- Orchestration with Apache Airflow or Prefect for automated daily runs