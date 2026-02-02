# Terraform Infrastructure

Terraform-based infrastructure-as-code for managing Dune Analytics resources.

## Overview

This directory contains a custom Terraform module for managing Dune Analytics queries and materialized views. Since there's no official Dune Terraform provider, the module uses the REST API directly via shell scripts.

## Structure

```
terraform/
├── README.md              # This file
├── Makefile               # Convenience commands
├── .gitignore             # Terraform-specific ignores
├── modules/
│   └── dune/              # Dune Analytics module
│       ├── README.md      # Module documentation
│       ├── main.tf        # Main resource definitions
│       ├── variables.tf   # Input variables
│       ├── outputs.tf     # Output definitions
│       ├── locals.tf      # Local computed values
│       ├── versions.tf    # Provider version constraints
│       ├── scripts/       # API helper scripts
│       └── tests/         # Terraform native tests
└── examples/
    └── simple/            # Simple standalone example
```

## Quick Start

```bash
# 1. Set your Dune API key
export DUNE_API_KEY="your-api-key"

# 2. Initialize Terraform
make init

# 3. Preview changes
make plan

# 4. Apply changes
make apply
```

## Available Commands

| Command | Description |
|---------|-------------|
| `make init` | Initialize Terraform working directory |
| `make validate` | Validate Terraform configuration |
| `make fmt` | Format Terraform files |
| `make plan` | Preview infrastructure changes |
| `make apply` | Apply infrastructure changes |
| `make destroy` | Destroy all infrastructure |
| `make clean` | Clean up temporary files |
| `make test` | Run module tests |
| `make outputs` | Show Terraform outputs |
| `make state` | List resources in state |

## Module Features

The Dune module (`modules/dune/`) provides:

### Query Management
- Create, update, and archive queries
- Unarchive queries for disaster recovery
- Control query visibility (private/public)
- SQL hash-based drift detection

### Materialized Views
- Full lifecycle management (create, update, delete)
- Configurable refresh schedules (cron expressions)
- Performance tier selection (medium/large)

### Data Discovery (Optional)
- List available datasets for schema exploration
- List existing materialized views for state reconciliation
- Monitor API usage and billing data

## Usage Example

```hcl
module "dune_dashboard" {
  source = "./modules/dune"

  team         = "1inch"
  dune_api_key = var.dune_api_key
  query_prefix = "[1inch Dashboard]"
  is_private   = true

  queries = {
    revenue_daily = {
      name = "Revenue Daily Totals"
      sql  = <<-SQL
        SELECT date_trunc('day', block_time) as date,
               sum(amount_usd) as revenue
        FROM dex.trades
        GROUP BY 1
      SQL
    }
  }

  materialized_views = {
    result_revenue_daily = {
      query_key = "revenue_daily"
      cron      = "0 */1 * * *"  # Every hour
    }
  }

  # Optional: Enable data discovery
  enable_usage_monitoring   = true
  enable_dataset_discovery  = true
  enable_matview_discovery  = true
}
```

## API Endpoints Implemented

### Query Management
| Endpoint | Method | Script |
|----------|--------|--------|
| `/v1/query` | POST | `create_query.sh` |
| `/v1/query/{id}` | PATCH | `update_query.sh` |
| `/v1/query/{id}` | GET | `get_query.sh` |
| `/v1/query/{id}/archive` | POST | `archive_query.sh` |
| `/v1/query/{id}/unarchive` | POST | `unarchive_query.sh` |
| `/v1/query/{id}/private` | POST | `private_query.sh` |
| `/v1/query/{id}/unprivate` | POST | `unprivate_query.sh` |

### Materialized Views
| Endpoint | Method | Script |
|----------|--------|--------|
| `/v1/materialized-views` | POST | `create_matview.sh` |
| `/v1/materialized-views` | GET | `list_matviews.sh` |
| `/v1/materialized-views/{name}` | GET | `get_matview.sh` |
| `/v1/materialized-views/{name}` | DELETE | `delete_matview.sh` |
| `/v1/materialized-views/{name}/refresh` | POST | `refresh_matview.sh` |

### Data Sources
| Endpoint | Method | Script |
|----------|--------|--------|
| `/v1/datasets` | GET | `list_datasets.sh` |
| `/v1/datasets/{ns}/{name}` | GET | `get_dataset.sh` |
| `/v1/usage` | POST | `get_usage.sh` |

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `DUNE_API_KEY` | Dune Analytics API key | Yes |
| `TF_VAR_dune_api_key` | Alternative way to pass API key to Terraform | No |

## Remote State (Recommended for Teams)

For team collaboration, configure a remote backend:

```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "dune/terraform.tfstate"
    region = "us-east-1"
  }
}
```

## Import Existing Resources

If you have queries deployed via other tools:

```bash
# Import a query by its Dune ID
make import KEY=revenue_daily_totals ID=6612997
```

## Testing

The module includes comprehensive tests using Terraform's native testing framework:

```bash
# Run all tests
make test

# Run tests directly
cd modules/dune && terraform test
```

### Test Coverage

| Test File | Tests | Description |
|-----------|-------|-------------|
| `unit.tftest.hcl` | 9 | Core module functionality |
| `validation.tftest.hcl` | 8 | Input validation |
| `outputs.tftest.hcl` | 6 | Output format verification |

## Comparison: Terraform vs Python Tool

| Feature | Python Tool (`dune/`) | Terraform Module |
|---------|----------------------|------------------|
| State Format | YAML (`state.yaml`) | Terraform state |
| Language | Python | HCL |
| Change Detection | SQL hash comparison | Terraform plan |
| Rollback | Manual | `terraform destroy` |
| CI/CD Integration | Custom scripts | Standard Terraform |
| Remote State | Git + state file | S3, GCS, Azure, etc. |
| Mat View Delete | Not supported | Supported |

## Requirements

- Terraform >= 1.0
- `jq` command-line tool
- `curl` command-line tool
- Dune API key with write permissions (Analyst plan or higher)

## Related Documentation

- [Dune Module README](modules/dune/README.md)
- [Simple Example](examples/simple/README.md)
- [Dune API Reference](https://docs.dune.com/api-reference)
- [Terraform Module Development](https://developer.hashicorp.com/terraform/language/modules/develop)
