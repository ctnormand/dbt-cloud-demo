terraform {
  backend "s3" {
    bucket = "databasement-terraform"
    key    = "dbt-core-demo/state.tfstate"
    region = "us-east-2"
  }
  required_providers {
    snowflake = {
      source  = "Snowflake-Labs/snowflake"
      version = "0.94.1"
    }
  }
}

provider "snowflake" {
  # Configuration set via environment variables
}

resource "snowflake_warehouse" "dbt_cloud_wh" {
  name           = "DBT_CLOUD_WH"
  comment        = "Warehouse for dbt Cloud demo"
  warehouse_size = "x-small"
  auto_resume    = "true"
  auto_suspend   = 300
}

resource "snowflake_database" "dbt_cloud_db" {
  name    = "JAFFLE_SHOP"
  comment = "Database for dbt Cloud demo"

}

resource "snowflake_user" "dbt_cloud_service_user" {
  name              = "SVC_DBT_CLOUD"
  comment           = "Service user for dbt Cloud"
  default_warehouse = snowflake_warehouse.dbt_cloud_wh.name
  default_namespace = snowflake_database.dbt_cloud_db.name
}
