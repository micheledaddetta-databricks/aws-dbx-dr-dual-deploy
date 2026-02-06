terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    databricks = {
      source = "databricks/databricks"
    }
    random = {
      source = "hashicorp/random"
    }
    time = {
      source = "hashicorp/time"
    }
    null = {
      source = "hashicorp/null"
    }
    restapi = {
      source  = "Mastercard/restapi"
      version = "3.0.0-rc2"
    }
  }
}

provider "aws" {
  alias   = "primary"
  profile = "primary-account"
  region  = var.location
}

provider "aws" {
  alias   = "secondary"
  profile = "secondary-account"
  region  = var.location_secondary
}

provider "random" {}

provider "time" {}

provider "null" {}

# Provider for account-level operations (Unity Catalog, NCC)
provider "databricks" {
  alias         = "account"
  account_id    = var.databricks_account_id
  host          = "https://accounts.cloud.databricks.com"
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

# Provider for workspace-level operations (External Location, etc.)
provider "databricks" {
  alias         = "primary-workspace"
  host          = module.databricks_workspace.workspace_url
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

# Provider for secondary workspace-level operations
provider "databricks" {
  alias         = "secondary-workspace"
  host          = var.deploy_secondary_workspace ? module.databricks_workspace_secondary[0].workspace_url : "https://placeholder.cloud.databricks.com"
  client_id     = var.databricks_client_id
  client_secret = var.databricks_client_secret
}

provider "restapi" {
  uri                  = "https://accounts.cloud.databricks.com"
  write_returns_object = true
  debug                = true

  headers = {
    "Content-Type" = "application/json"
  }

  oauth_client_credentials {
    oauth_client_id      = var.databricks_client_id
    oauth_client_secret  = var.databricks_client_secret
    oauth_scopes         = ["all-apis"]
    oauth_token_endpoint = "https://accounts.cloud.databricks.com/oidc/accounts/${var.databricks_account_id}/v1/token"
  }

  create_method  = "PATCH"
  update_method  = "PATCH"
  destroy_method = "PATCH"
}