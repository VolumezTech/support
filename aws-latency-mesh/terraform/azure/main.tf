# terraform/azure/main.tf - Azure Full-Mesh Latency Measurement Infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# =============================================================================
# SSH Key Generation
# =============================================================================

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# =============================================================================
# Variables
# =============================================================================

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_D2s_v3"  # D-series has highest availability across regions
}

variable "admin_username" {
  description = "Azure VM admin username"
  type        = string
  default     = "azureuser"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "latency-mesh"
}

# Local values
locals {
  common_tags = {
    Project   = "latency-measurement"
    ManagedBy = "terraform"
    Cloud     = "azure"
  }

  # Azure regions with availability zones (25 regions)
  azure_regions = {
    eastus             = ["1", "2", "3"]
    eastus2            = ["1", "2", "3"]
    westus2            = ["1", "2", "3"]
    westus3            = ["1", "2", "3"]
    centralus          = ["1", "2", "3"]
    southcentralus     = ["1", "2", "3"]
    canadacentral      = ["1", "2", "3"]
    brazilsouth        = ["1", "2", "3"]
    uksouth            = ["1", "2", "3"]
    westeurope         = ["1", "2", "3"]
    northeurope        = ["1", "2", "3"]
    francecentral      = ["1", "2", "3"]
    germanywestcentral = ["1", "2", "3"]
    norwayeast         = ["1", "2", "3"]
    swedencentral      = ["1", "2", "3"]
    switzerlandnorth   = ["1", "2", "3"]
    uaenorth           = ["1", "2", "3"]
    southafricanorth   = ["1", "2", "3"]
    qatarcentral       = ["1", "2", "3"]
    australiaeast      = ["1", "2", "3"]
    southeastasia      = ["1", "2", "3"]
    eastasia           = ["1", "2", "3"]
    japaneast          = ["1", "2", "3"]
    koreacentral       = ["1", "2", "3"]
    centralindia       = ["1", "2", "3"]
  }
}

# =============================================================================
# Azure Provider configuration
# =============================================================================

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# =============================================================================
# Azure Module deployments (25 regions)
# =============================================================================

module "eastus" {
  source         = "./modules/azure-region"
  region         = "eastus"
  zones          = local.azure_regions["eastus"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "eastus2" {
  source         = "./modules/azure-region"
  region         = "eastus2"
  zones          = local.azure_regions["eastus2"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "westus2" {
  source         = "./modules/azure-region"
  region         = "westus2"
  zones          = local.azure_regions["westus2"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "westus3" {
  source         = "./modules/azure-region"
  region         = "westus3"
  zones          = local.azure_regions["westus3"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "centralus" {
  source         = "./modules/azure-region"
  region         = "centralus"
  zones          = local.azure_regions["centralus"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "southcentralus" {
  source         = "./modules/azure-region"
  region         = "southcentralus"
  zones          = local.azure_regions["southcentralus"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "canadacentral" {
  source         = "./modules/azure-region"
  region         = "canadacentral"
  zones          = local.azure_regions["canadacentral"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "brazilsouth" {
  source         = "./modules/azure-region"
  region         = "brazilsouth"
  zones          = local.azure_regions["brazilsouth"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "uksouth" {
  source         = "./modules/azure-region"
  region         = "uksouth"
  zones          = local.azure_regions["uksouth"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "westeurope" {
  source         = "./modules/azure-region"
  region         = "westeurope"
  zones          = local.azure_regions["westeurope"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "northeurope" {
  source         = "./modules/azure-region"
  region         = "northeurope"
  zones          = local.azure_regions["northeurope"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "francecentral" {
  source         = "./modules/azure-region"
  region         = "francecentral"
  zones          = local.azure_regions["francecentral"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "germanywestcentral" {
  source         = "./modules/azure-region"
  region         = "germanywestcentral"
  zones          = local.azure_regions["germanywestcentral"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "norwayeast" {
  source         = "./modules/azure-region"
  region         = "norwayeast"
  zones          = local.azure_regions["norwayeast"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "swedencentral" {
  source         = "./modules/azure-region"
  region         = "swedencentral"
  zones          = local.azure_regions["swedencentral"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "switzerlandnorth" {
  source         = "./modules/azure-region"
  region         = "switzerlandnorth"
  zones          = local.azure_regions["switzerlandnorth"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "uaenorth" {
  source         = "./modules/azure-region"
  region         = "uaenorth"
  zones          = local.azure_regions["uaenorth"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "southafricanorth" {
  source         = "./modules/azure-region"
  region         = "southafricanorth"
  zones          = local.azure_regions["southafricanorth"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "qatarcentral" {
  source         = "./modules/azure-region"
  region         = "qatarcentral"
  zones          = local.azure_regions["qatarcentral"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "australiaeast" {
  source         = "./modules/azure-region"
  region         = "australiaeast"
  zones          = local.azure_regions["australiaeast"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "southeastasia" {
  source         = "./modules/azure-region"
  region         = "southeastasia"
  zones          = local.azure_regions["southeastasia"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "eastasia" {
  source         = "./modules/azure-region"
  region         = "eastasia"
  zones          = local.azure_regions["eastasia"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "japaneast" {
  source         = "./modules/azure-region"
  region         = "japaneast"
  zones          = local.azure_regions["japaneast"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "koreacentral" {
  source         = "./modules/azure-region"
  region         = "koreacentral"
  zones          = local.azure_regions["koreacentral"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

module "centralindia" {
  source         = "./modules/azure-region"
  region         = "centralindia"
  zones          = local.azure_regions["centralindia"]
  vm_size        = var.vm_size
  project_name   = var.project_name
  admin_username = var.admin_username
  ssh_public_key = tls_private_key.ssh_key.public_key_openssh
}

# =============================================================================
# Outputs
# =============================================================================

output "instances" {
  description = "All Azure instances across all regions"
  value = merge(
    module.eastus.instances,
    module.eastus2.instances,
    module.westus2.instances,
    module.westus3.instances,
    module.centralus.instances,
    module.southcentralus.instances,
    module.canadacentral.instances,
    module.brazilsouth.instances,
    module.uksouth.instances,
    module.westeurope.instances,
    module.northeurope.instances,
    module.francecentral.instances,
    module.germanywestcentral.instances,
    module.norwayeast.instances,
    module.swedencentral.instances,
    module.switzerlandnorth.instances,
    module.uaenorth.instances,
    module.southafricanorth.instances,
    module.qatarcentral.instances,
    module.australiaeast.instances,
    module.southeastasia.instances,
    module.eastasia.instances,
    module.japaneast.instances,
    module.koreacentral.instances,
    module.centralindia.instances,
  )
}

output "regions" {
  description = "List of Azure regions deployed"
  value       = keys(local.azure_regions)
}

output "ssh_private_key" {
  description = "Private SSH key for Azure instances - save this to a file for SSH access"
  value       = tls_private_key.ssh_key.private_key_pem
  sensitive   = true
}

output "ssh_user" {
  description = "SSH user for Azure instances"
  value       = var.admin_username
}
