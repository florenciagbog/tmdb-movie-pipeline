#!/usr/bin/env bash
# Deploys the TMDB pipeline as a Cloud Run Job triggered daily by Cloud Scheduler.
# Run it from the gcp/ folder in Cloud Shell:   bash deploy.sh
# Safe to re-run: it updates whatever already exists.
set -euo pipefail

PROJECT_ID="${PROJECT_ID:-tmdb-data-engineering}"
REGION="${REGION:-europe-west1}"           # Cloud Run + Scheduler region
BQ_LOCATION="${BQ_LOCATION:-EU}"           # must match your BigQuery datasets
SCHEDULE="${SCHEDULE:-0 9 * * *}"          # every day 09:00 ...
SCHEDULE_TZ="${SCHEDULE_TZ:-Europe/Rome}"  # ... Rome time
JOB_NAME="tmdb-pipeline"
SCHEDULER_NAME="tmdb-pipeline-daily"
SECRET_NAME="tmdb-api-key"
SA_NAME="tmdb-pipeline-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "==> Project ${PROJECT_ID}, region ${REGION}, BigQuery location ${BQ_LOCATION}"
gcloud config set project "${PROJECT_ID}" >/dev/null

echo "==> Enabling APIs"
gcloud services enable \
  run.googleapis.com cloudscheduler.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com secretmanager.googleapis.com bigquery.googleapis.com

echo "==> Service account"
if ! gcloud iam service-accounts describe "${SA_EMAIL}" >/dev/null 2>&1; then
  gcloud iam service-accounts create "${SA_NAME}" --display-name "TMDB pipeline runner"
  sleep 10  # let IAM propagate
fi
for ROLE in roles/bigquery.dataEditor roles/bigquery.jobUser roles/run.invoker; do
  gcloud projects add-iam-policy-binding "${PROJECT_ID}" \
    --member "serviceAccount:${SA_EMAIL}" --role "${ROLE}" --condition=None >/dev/null
done

echo "==> TMDB API key in Secret Manager"
if ! gcloud secrets describe "${SECRET_NAME}" >/dev/null 2>&1; then
  read -r -s -p "Paste your TMDB API key (input hidden): " TMDB_KEY; echo
  printf '%s' "${TMDB_KEY}" | gcloud secrets create "${SECRET_NAME}" --data-file=- --replication-policy=automatic
  unset TMDB_KEY
fi
gcloud secrets add-iam-policy-binding "${SECRET_NAME}" \
  --member "serviceAccount:${SA_EMAIL}" --role roles/secretmanager.secretAccessor >/dev/null

echo "==> Building and deploying Cloud Run job (takes a few minutes)"
gcloud run jobs deploy "${JOB_NAME}" \
  --source . \
  --region "${REGION}" \
  --service-account "${SA_EMAIL}" \
  --set-secrets "TMDB_API_KEY=${SECRET_NAME}:latest" \
  --set-env-vars "GCP_PROJECT_ID=${PROJECT_ID},BQ_LOCATION=${BQ_LOCATION},PIPELINE_TZ=${SCHEDULE_TZ}" \
  --tasks 1 --max-retries 1 --task-timeout 30m \
  --memory 512Mi --cpu 1

echo "==> Daily schedule (${SCHEDULE} ${SCHEDULE_TZ})"
RUN_URI="https://run.googleapis.com/v2/projects/${PROJECT_ID}/locations/${REGION}/jobs/${JOB_NAME}:run"
if gcloud scheduler jobs describe "${SCHEDULER_NAME}" --location "${REGION}" >/dev/null 2>&1; then
  ACTION=update
else
  ACTION=create
fi
gcloud scheduler jobs "${ACTION}" http "${SCHEDULER_NAME}" \
  --location "${REGION}" \
  --schedule "${SCHEDULE}" \
  --time-zone "${SCHEDULE_TZ}" \
  --uri "${RUN_URI}" \
  --http-method POST \
  --oauth-service-account-email "${SA_EMAIL}"

echo
echo "Deployed. Run it now with:"
echo "  gcloud run jobs execute ${JOB_NAME} --region ${REGION} --wait"
