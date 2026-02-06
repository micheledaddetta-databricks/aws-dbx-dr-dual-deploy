terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.primary, aws.secondary]
    }
    databricks = {
      source = "databricks/databricks"
    }
    time = {
      source = "hashicorp/time"
    }
  }
}
