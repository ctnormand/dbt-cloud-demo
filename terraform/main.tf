/*******************************************************************************
TERRAFORM BACKEND & PROVIDERS
*******************************************************************************/
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

/*******************************************************************************
WAREHOUSE & DATABASE
*******************************************************************************/
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

/*******************************************************************************
USERS, ROLES, & PRIVILEGES
*******************************************************************************/
resource "snowflake_user" "dbt_cloud_service_user" {
  name              = "SVC_DBT_CLOUD"
  comment           = "Service user for dbt Cloud"
  default_warehouse = snowflake_warehouse.dbt_cloud_wh.name
  default_namespace = snowflake_database.dbt_cloud_db.name
}

resource "snowflake_account_role" "dbt_prod_role" {
  name    = "DBT_PROD_RUNNER"
  comment = "Database role for dbt Cloud production runner"
}

resource "snowflake_grant_account_role" "dbt_prod_grant" {
  role_name = snowflake_account_role.dbt_prod_role.name
  user_name = snowflake_user.dbt_cloud_service_user.name
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_privileges" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.dbt_prod_role.name
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.dbt_cloud_wh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "raw_schema_privileges" {
  privileges        = ["USAGE"]
  account_role_name = snowflake_account_role.dbt_prod_role.name
  on_schema {
    schema_name = "\"${snowflake_database.dbt_cloud_db.name}\".\"RAW\"" # note this is a fully qualified name!
  }
}

resource "snowflake_grant_privileges_to_account_role" "raw_table_privileges" {
  privileges        = ["SELECT"]
  account_role_name = snowflake_account_role.dbt_prod_role.name
  on_schema_object {
    all {
      object_type_plural = "TABLES"
      in_schema          = "\"${snowflake_database.dbt_cloud_db.name}\".\"RAW\"" # note this is a fully qualified name!
    }
  }
}

resource "snowflake_grant_privileges_to_account_role" "jaffle_shop_db_privileges" {
  privileges        = ["USAGE", "CREATE SCHEMA"]
  account_role_name = snowflake_account_role.dbt_prod_role.name
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.dbt_cloud_db.name
  }
}

/*******************************************************************************
NETWORK POLICY
*******************************************************************************/
resource "snowflake_network_policy" "dbt_cloud_network_policy" {
  name    = "dbt_cloud_network_policy"
  comment = "Network policy to allow connections from dbt Cloud"
  allowed_ip_list = [
    "52.45.144.63",
    "54.81.134.249",
    "52.22.161.231",
    "52.3.77.232",
    "3.214.191.130",
    "34.233.79.135"
  ]
}

resource "snowflake_network_policy_attachment" "dbt_cloud_network_policy_attachment" {
  network_policy_name = snowflake_network_policy.dbt_cloud_network_policy.name
  users               = [snowflake_user.dbt_cloud_service_user.name]
  set_for_account     = false
}
