#!/bin/bash
# verify_matview.sh - Verify materialized view state matches expected configuration
# 
# This script checks if the actual Dune mat view exists and has the expected query_id.
# 
# NOTE: The Dune GET /materialized-views/{name} API does NOT return cron_schedule
# or performance settings. We can only verify existence and query_id.
# See: https://docs.dune.com/api-reference/materialized-views/get
#
# Input (via stdin as JSON):
#   - name: Full mat view name (e.g., "dune.1inch.result_1inch_live_overview")
#   - expected_cron: Expected cron expression (cannot verify via API)
#   - expected_query_id: Expected query ID
#
# Output (JSON):
#   - status: "ok" if matches, "drift" if mismatch, "missing" if not found
#   - actual_cron: Always "unknown" (API limitation)
#   - actual_query_id: Actual query ID
#   - message: Human-readable status message

set -e

# Read input
INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')
EXPECTED_CRON=$(echo "$INPUT" | jq -r '.expected_cron // ""')
EXPECTED_QUERY_ID=$(echo "$INPUT" | jq -r '.expected_query_id // ""')

# Check if API key is set
if [ -z "$DUNE_API_KEY" ]; then
  echo '{"status":"skip","actual_cron":"unknown","actual_query_id":"0","message":"DUNE_API_KEY not set, skipping verification"}'
  exit 0
fi

API_BASE="${DUNE_API_BASE_URL:-https://api.dune.com/api/v1}"

# Fetch current mat view state from Dune
RESPONSE=$(curl -s -H "X-Dune-Api-Key: $DUNE_API_KEY" "$API_BASE/materialized-views/$NAME" 2>/dev/null || echo '{"error":"fetch_failed"}')

# Check if mat view exists
if echo "$RESPONSE" | jq -e '.error' > /dev/null 2>&1; then
  echo '{"status":"missing","actual_cron":"unknown","actual_query_id":"0","message":"Materialized view does not exist"}'
  exit 0
fi

# Extract actual values
# NOTE: cron_schedule is NOT returned by the API - we cannot verify it
ACTUAL_QUERY_ID=$(echo "$RESPONSE" | jq -r '.query_id // 0')

# Check for drift (only query_id can be verified)
DRIFT=""
MESSAGE="Materialized view exists"

# API does not return cron_schedule, so we cannot verify it
# We only output a note that cron cannot be verified via API
ACTUAL_CRON="unknown"

if [ "$ACTUAL_QUERY_ID" != "$EXPECTED_QUERY_ID" ] && [ -n "$EXPECTED_QUERY_ID" ] && [ "$EXPECTED_QUERY_ID" != "0" ]; then
  DRIFT="query_id_mismatch"
  MESSAGE="DRIFT: query_id is '$ACTUAL_QUERY_ID' but expected '$EXPECTED_QUERY_ID'"
fi

# Output result
if [ -n "$DRIFT" ]; then
  jq -n \
    --arg status "drift" \
    --arg actual_cron "$ACTUAL_CRON" \
    --arg actual_query_id "$ACTUAL_QUERY_ID" \
    --arg message "$MESSAGE" \
    '{status: $status, actual_cron: $actual_cron, actual_query_id: $actual_query_id, message: $message}'
else
  jq -n \
    --arg status "ok" \
    --arg actual_cron "$ACTUAL_CRON" \
    --arg actual_query_id "$ACTUAL_QUERY_ID" \
    --arg message "$MESSAGE (note: cron_schedule cannot be verified via API)" \
    '{status: $status, actual_cron: $actual_cron, actual_query_id: $actual_query_id, message: $message}'
fi
