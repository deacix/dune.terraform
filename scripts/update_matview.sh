#!/bin/bash
# =============================================================================
# Update Materialized View Script
# =============================================================================
# Updates an existing materialized view on Dune Analytics via the upsert API.
# This ensures cron_expression and performance are always in sync.
#
# Usage: ./update_matview.sh
# Reads JSON input from stdin with: name, query_id, cron, performance
# Outputs JSON with: name, full_name, updated, execution_id
#
# Environment: DUNE_API_KEY must be set
#
# API Reference: https://docs.dune.com/api-reference/materialized-views/create
# The upsert endpoint (POST /materialized-views) creates or updates:
#   - Creates new mat view if none exists for the given query_id
#   - Updates existing mat view if query_id matches
#
# Parameters:
#   - name: Mat view name (must be prefixed with result_)
#   - query_id: Integer query ID
#   - cron_expression: 5-section cron (min 15 mins, max weekly)
#   - performance: "medium" or "large"
#   - is_private: Boolean (optional)

set -e

# Read input from stdin
INPUT=$(cat)

# Extract parameters
NAME=$(echo "$INPUT" | jq -r '.name')
QUERY_ID=$(echo "$INPUT" | jq -r '.query_id')
CRON=$(echo "$INPUT" | jq -r '.cron')
PERFORMANCE=$(echo "$INPUT" | jq -r '.performance // "medium"')
IS_PRIVATE=$(echo "$INPUT" | jq -r '.is_private // "true"')
TEAM=$(echo "$INPUT" | jq -r '.team // empty')
API_URL="${DUNE_API_URL:-https://api.dune.com/api/v1}"

# Validate
if [ -z "$DUNE_API_KEY" ]; then
    echo '{"error": "DUNE_API_KEY environment variable not set"}' >&2
    exit 1
fi

if [ -z "$NAME" ] || [ "$NAME" = "null" ]; then
    echo '{"error": "name is required"}' >&2
    exit 1
fi

if [ -z "$QUERY_ID" ] || [ "$QUERY_ID" = "null" ]; then
    echo '{"error": "query_id is required"}' >&2
    exit 1
fi

if [ -z "$CRON" ] || [ "$CRON" = "null" ]; then
    echo '{"error": "cron is required"}' >&2
    exit 1
fi

# Upsert materialized view via API
# This will update existing mat view if query_id matches, or create if not exists
RESPONSE=$(curl -s -X POST \
    -H "X-Dune-API-Key: $DUNE_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
        --arg name "$NAME" \
        --argjson query_id "$QUERY_ID" \
        --arg cron_expression "$CRON" \
        --arg performance "$PERFORMANCE" \
        --argjson is_private "$IS_PRIVATE" \
        '{name: $name, query_id: $query_id, cron_expression: $cron_expression, performance: $performance, is_private: $is_private}')" \
    "$API_URL/materialized-views")

# Check for errors
ERROR=$(echo "$RESPONSE" | jq -r '.error // empty')
if [ -n "$ERROR" ]; then
    # "already exists" with different query_id is a real error
    echo "{\"error\": \"$ERROR\"}" >&2
    exit 1
fi

# Extract execution_id from response (indicates refresh was triggered)
EXECUTION_ID=$(echo "$RESPONSE" | jq -r '.execution_id // empty')
FULL_NAME=$(echo "$RESPONSE" | jq -r '.name // empty')

# If no full_name in response, construct it
if [ -z "$FULL_NAME" ] || [ "$FULL_NAME" = "null" ]; then
    FULL_NAME="dune.$TEAM.$NAME"
fi

# Output result
jq -n \
    --arg name "$NAME" \
    --arg full_name "$FULL_NAME" \
    --arg execution_id "$EXECUTION_ID" \
    '{name: $name, full_name: $full_name, updated: "true", execution_id: $execution_id}'
