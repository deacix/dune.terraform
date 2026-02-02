# Terraform Module: Dune Analytics

A Terraform module for managing Dune Analytics queries and materialized views as infrastructure-as-code.

## Features

- **Query Management**: Create, update, archive, and unarchive Dune queries
- **Query Visibility**: Control query privacy (private/public)
- **Materialized Views**: Full lifecycle management (create, update, delete) with configurable refresh schedules
- **State Tracking**: Track query IDs, versions, and SQL hashes
- **Drift Detection**: Detect changes between local SQL and deployed queries
- **Data Discovery**: Optional dataset and materialized view listing
- **Usage Monitoring**: Optional API usage and billing data

## Prerequisites

- Terraform >= 1.0
- Dune API Key with write access
- (Optional) Team workspace on Dune

## Usage

### Basic Example

```hcl
module "dune_dashboard" {
  source = "./modules/dune"

  team         = "1inch"
  query_prefix = "[1inch Dashboard]"
  query_folder = "Dashboard"
  is_private   = true

  queries = {
    revenue_daily_totals = {
      name        = "Revenue Daily Totals"
      description = "Daily aggregated revenue metrics"
      sql_file    = "${path.module}/queries/revenue_daily_totals.sql"
    }
    revenue_by_product = {
      name        = "Revenue by Product"
      description = "Revenue breakdown by product mode"
      sql_file    = "${path.module}/queries/revenue_by_product.sql"
    }
  }

  materialized_views = {
    result_1inch_revenue_daily = {
      query_key   = "revenue_daily_totals"
      cron        = "0 */1 * * *"  # Every hour
      performance = "medium"
    }
    result_1inch_revenue_by_product = {
      query_key   = "revenue_by_product"
      cron        = "0 */1 * * *"
      performance = "medium"
    }
  }
}
```

### With Provider Configuration

```hcl
provider "dune" {
  api_key = var.dune_api_key
}

module "dune_dashboard" {
  source = "./modules/dune"
  
  # ... configuration
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `team` | Dune team/namespace name | `string` | n/a | yes |
| `query_prefix` | Prefix for all query names (e.g., "[1inch Dashboard]") | `string` | `""` | no |
| `query_folder` | Folder name for organizing queries | `string` | `""` | no |
| `is_private` | Whether queries are private | `bool` | `true` | no |
| `default_performance` | Default performance tier for mat views | `string` | `"medium"` | no |
| `queries` | Map of query definitions | `map(object)` | `{}` | no |
| `materialized_views` | Map of materialized view definitions | `map(object)` | `{}` | no |
| `enable_usage_monitoring` | Enable fetching API usage/billing data | `bool` | `false` | no |
| `enable_dataset_discovery` | Enable listing available datasets | `bool` | `false` | no |
| `enable_matview_discovery` | Enable listing existing materialized views | `bool` | `false` | no |

### Query Object Schema

```hcl
queries = {
  query_key = {
    name        = string           # Query name (without prefix)
    description = optional(string) # Query description
    sql_file    = string           # Path to SQL file
    sql         = optional(string) # Inline SQL (alternative to sql_file)
    tags        = optional(list)   # Query tags
    private     = optional(bool)   # Override default privacy setting
  }
}
```

### Materialized View Object Schema

```hcl
materialized_views = {
  view_name = {
    query_key   = string           # Key from queries map
    cron        = string           # Cron expression for refresh
    performance = optional(string) # "medium" or "large"
  }
}
```

## Outputs

| Name | Description |
|------|-------------|
| `query_ids` | Map of query keys to their Dune query IDs |
| `query_urls` | Map of query keys to their Dune URLs |
| `materialized_view_names` | Map of mat view keys to their full names |
| `workspace_folder_url` | URL to the workspace folder on Dune |
| `usage` | API usage data (when `enable_usage_monitoring = true`) |
| `datasets` | Available datasets (when `enable_dataset_discovery = true`) |
| `existing_materialized_views` | Existing mat views (when `enable_matview_discovery = true`) |

## State Management

This module tracks:

- Query IDs for each deployed query
- SQL content hashes for drift detection
- Materialized view configurations

### Import Existing Queries

```bash
# Import an existing query into Terraform state
terraform import 'module.dune_dashboard.dune_query.queries["revenue_daily_totals"]' 6612997
```

## SQL File Format

SQL files can include metadata in header comments:

```sql
-- name: Revenue Daily Totals
-- description: Daily aggregated revenue metrics
-- tags: revenue, dashboard, daily
-- private: true

SELECT
    date_trunc('day', block_time) as date,
    sum(transfer_amount_usd) as collections
FROM "query_5360158(from='2024-10-01 00:00:00')"
GROUP BY 1
ORDER BY 1 DESC
```

## Cron Expression Reference

| Schedule | Expression |
|----------|------------|
| Every hour | `0 */1 * * *` |
| Every 2 hours | `0 */2 * * *` |
| Every 6 hours | `0 */6 * * *` |
| Daily at midnight | `0 0 * * *` |
| Weekly (Sunday midnight) | `0 0 * * 0` |

## Testing

The module includes comprehensive tests using Terraform's native testing framework.

### Running Tests

```bash
# From the module directory
cd infra/terraform/modules/dune
terraform init
terraform test

# Or using the Makefile
cd infra/terraform
make test
```

### Test Structure

```
tests/
├── unit.tftest.hcl       # Unit tests for module logic
├── validation.tftest.hcl # Input validation tests
└── outputs.tftest.hcl    # Output format tests
```

### Test Coverage

| Test File | Tests | Description |
|-----------|-------|-------------|
| `unit.tftest.hcl` | 9 | Core module functionality (naming, hashing, configuration) |
| `validation.tftest.hcl` | 8 | Input validation (required fields, valid values) |
| `outputs.tftest.hcl` | 6 | Output format and structure verification |

## Architecture

```
infra/terraform/modules/dune/
├── README.md           # This file
├── main.tf             # Main resource definitions
├── variables.tf        # Input variable definitions
├── outputs.tf          # Output definitions
├── locals.tf           # Local computed values
├── versions.tf         # Version constraints
├── scripts/            # Helper scripts for API calls
│   ├── create_query.sh
│   ├── update_query.sh
│   ├── get_query.sh
│   ├── archive_query.sh
│   ├── unarchive_query.sh
│   ├── private_query.sh
│   ├── unprivate_query.sh
│   ├── create_matview.sh
│   ├── get_matview.sh
│   ├── list_matviews.sh
│   ├── delete_matview.sh
│   ├── refresh_matview.sh
│   ├── list_datasets.sh
│   ├── get_dataset.sh
│   └── get_usage.sh
└── tests/              # Terraform tests
    ├── unit.tftest.hcl
    ├── validation.tftest.hcl
    └── outputs.tftest.hcl
```

## Data Discovery

Enable optional data sources to discover existing resources:

```hcl
module "dune_dashboard" {
  source = "./modules/dune"
  
  team         = "1inch"
  dune_api_key = var.dune_api_key
  
  # Enable data discovery
  enable_usage_monitoring   = true
  enable_dataset_discovery  = true
  enable_matview_discovery  = true
  
  # ... queries and materialized_views
}

# Access discovered data
output "credits_used" {
  value = module.dune_dashboard.usage.credits_used
}

output "available_datasets" {
  value = module.dune_dashboard.datasets.datasets
}
```

## API Endpoints

This module implements the following Dune API endpoints:

### Query Management
| Script | Endpoint | Method | Purpose |
|--------|----------|--------|---------|
| `create_query.sh` | `/v1/query` | POST | Create new query |
| `update_query.sh` | `/v1/query/{id}` | PATCH | Update existing query |
| `get_query.sh` | `/v1/query/{id}` | GET | Read query details |
| `archive_query.sh` | `/v1/query/{id}/archive` | POST | Archive (soft delete) query |
| `unarchive_query.sh` | `/v1/query/{id}/unarchive` | POST | Restore archived query |
| `private_query.sh` | `/v1/query/{id}/private` | POST | Make query private |
| `unprivate_query.sh` | `/v1/query/{id}/unprivate` | POST | Make query public |

### Materialized Views
| Script | Endpoint | Method | Purpose |
|--------|----------|--------|---------|
| `create_matview.sh` | `/v1/materialized-views` | POST | Create/upsert mat view |
| `get_matview.sh` | `/v1/materialized-views/{name}` | GET | Get mat view details |
| `list_matviews.sh` | `/v1/materialized-views` | GET | List all mat views |
| `delete_matview.sh` | `/v1/materialized-views/{name}` | DELETE | Delete mat view |
| `refresh_matview.sh` | `/v1/materialized-views/{name}/refresh` | POST | Trigger refresh |

### Data Sources
| Script | Endpoint | Method | Purpose |
|--------|----------|--------|---------|
| `list_datasets.sh` | `/v1/datasets` | GET | List available datasets |
| `get_dataset.sh` | `/v1/datasets/{ns}/{name}` | GET | Get dataset schema |
| `get_usage.sh` | `/v1/usage` | POST | Get API usage/billing |

## Notes

1. **API Rate Limits**: Dune API has rate limits. Large deployments may need batching.

2. **Folder Assignment**: The Dune API doesn't support folder assignment. Organize queries manually in the Dune UI.

3. **Mat View Lifecycle**: Materialized views are now properly deleted on `terraform destroy`.

4. **Refresh Timing**: Mat view refreshes are scheduled via cron. Initial data requires manual refresh or waiting for first cron trigger.

5. **Environment Variable**: The `DUNE_API_KEY` environment variable must be set for destroy operations to work properly.

## Related Resources

- [Dune API Documentation](https://docs.dune.com/api-reference)
- [Dune Query Guide](https://docs.dune.com/query-engine/writing-efficient-queries)
- [Terraform Module Development](https://developer.hashicorp.com/terraform/language/modules/develop)
