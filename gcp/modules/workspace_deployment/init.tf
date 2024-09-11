variable "databricks_account_id" {}
variable "databricks_google_service_account" {}
variable "google_project" {}
variable "google_region" {}

variable "workspace_pe" {}
variable "relay_pe" {}

variable "use_existing_cmek" {}
variable "key_name" {}
variable "keyring_name" {}
variable "cmek_resource_id" {}

variable "account_console_url" {}

# primary subnet providing ip addresses to PSC endpoints
variable "google_pe_subnet" {}

# Private ip address assigned to PSC endpoints
variable "relay_pe_ip_name" {}
variable "workspace_pe_ip_name" {}

variable "google_pe_subnet_ip_cidr_range" {
  default = "10.3.0.0/24"
}
variable "google_pe_subnet_secondary_ip_range" {
  default = "192.168.10.0/24"
}

variable "nodes_ip_cidr_range"{
  default = "10.0.0.0/16"
}

variable "pod_ip_cidr_range"{
  default = "10.1.0.0/16"
}

variable "service_ip_cidr_range"{
  default = "10.2.0.0/20"
}

variable "mws_workspace_gke_master_ip_range" {
  default = "10.3.0.0/28"
}

//Users can connect to workspace only from this list of IP's
variable "ip_addresses" {
  type = list(string)
}

// Regional value for the Hive Metastore IP (allowing Egress to this public IP)
variable "hive_metastore_ip" {
  default = "34.76.244.202"
}




/*
Databricks PSC service attachments
https://docs.gcp.databricks.com/resources/supported-regions.html#psc
*/

variable "relay_service_attachment" {}
variable "workspace_service_attachment" {}

terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      version = ">=1.51.0"
    }
    google = {
      source  = "hashicorp/google"
      version = ">= 6.2.0"
    }
  }
}

provider "google" {
  project = var.google_project
  region  = var.google_region
}

// initialize provider in "accounts" mode to provision new workspace
provider "databricks" {
  alias                  = "accounts"
  host                   = var.account_console_url
  google_service_account = var.databricks_google_service_account
  account_id             = var.databricks_account_id
}



data "google_client_openid_userinfo" "me" {
}

data "google_client_config" "current" {
}

resource "random_string" "suffix" {
  special = false
  upper   = false
  length  = 6
}

provider "databricks" {
 alias                  = "workspace"
 host                   = databricks_mws_workspaces.this.workspace_url
 google_service_account = var.databricks_google_service_account
}


data "databricks_group" "admins" {
 depends_on   = [databricks_mws_workspaces.this]
 provider     = databricks.workspace
 display_name = "admins"
}


resource "databricks_user" "me" {
 depends_on = [databricks_mws_workspaces.this]


 provider  = databricks.workspace
 user_name = data.google_client_openid_userinfo.me.email
}


resource "databricks_group_member" "allow_me_to_login" {
 depends_on = [databricks_mws_workspaces.this]

 provider  = databricks.workspace
 group_id  = data.databricks_group.admins.id
 member_id = databricks_user.me.id
}


