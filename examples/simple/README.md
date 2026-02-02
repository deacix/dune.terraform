# Simple Dune Terraform Example

A minimal example demonstrating how to use the Dune Terraform module.

## Prerequisites

- Terraform >= 1.0
- Dune API key with write access

## Quick Start

```bash
# 1. Set your API key
export DUNE_API_KEY="your-api-key"

# 2. Initialize Terraform
terraform init

# 3. Preview changes
terraform plan -var="dune_api_key=$DUNE_API_KEY" -var="team=your-team"

# 4. Apply changes
terraform apply -var="dune_api_key=$DUNE_API_KEY" -var="team=your-team"
```

## Using tfvars

Alternatively, create a `terraform.tfvars` file:

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform apply
```

## What This Example Creates

1. **Two Dune queries:**
   - `daily_transactions` - Daily transaction counts on Ethereum
   - `top_contracts` - Most active contracts by transaction count

2. **One materialized view:**
   - `result_daily_transactions` - Caches daily transactions, refreshes hourly

## Cleanup

```bash
terraform destroy -var="dune_api_key=$DUNE_API_KEY" -var="team=your-team"
```

## Customization

Edit `main.tf` to:
- Change the team name
- Modify query SQL
- Add more queries
- Adjust materialized view schedules
