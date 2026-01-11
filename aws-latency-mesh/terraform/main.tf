# main.tf - Multi-Cloud Full-Mesh Latency Measurement Infrastructure

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
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

# Generate SSH key for Azure VMs
resource "tls_private_key" "azure_ssh" {
  count     = var.enable_azure ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

# =============================================================================
# Variables
# =============================================================================

variable "enable_aws" {
  description = "Enable AWS deployment (must be explicitly set to true)"
  type        = bool
  default     = false
}

variable "enable_azure" {
  description = "Enable Azure deployment (must be explicitly set to true)"
  type        = bool
  default     = false
}

# AWS Variables
variable "aws_key_name" {
  description = "AWS SSH key pair name"
  type        = string
  default     = ""
}

variable "aws_public_key" {
  description = "SSH public key for AWS (if provided, creates key pair in each region)"
  type        = string
  default     = ""
}

variable "aws_instance_type" {
  description = "AWS EC2 instance type"
  type        = string
  default     = "t3.micro"
}

# Azure Variables
variable "azure_ssh_public_key" {
  description = "SSH public key for Azure VMs"
  type        = string
  default     = ""
}

variable "azure_vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B2s"
}

variable "azure_admin_username" {
  description = "Azure VM admin username"
  type        = string
  default     = "azureuser"
}

# Local values
locals {
  project_name = "latency-mesh"
  common_tags = {
    Project   = "latency-measurement"
    ManagedBy = "terraform"
  }

  # Azure regions with availability zones
  azure_regions = {
    eastus         = ["1", "2", "3"]
    eastus2        = ["1", "2", "3"]
    westus2        = ["1", "2", "3"]
    westus3        = ["1", "2", "3"]
    centralus      = ["1", "2", "3"]
    southcentralus = ["1", "2", "3"]
    canadacentral  = ["1", "2", "3"]
    brazilsouth    = ["1", "2", "3"]
    uksouth        = ["1", "2", "3"]
    westeurope     = ["1", "2", "3"]
    northeurope    = ["1", "2", "3"]
    francecentral  = ["1", "2", "3"]
    germanywestcentral = ["1", "2", "3"]
    norwayeast     = ["1", "2", "3"]
    swedencentral  = ["1", "2", "3"]
    switzerlandnorth = ["1", "2", "3"]
    uaenorth       = ["1", "2", "3"]
    southafricanorth = ["1", "2", "3"]
    qatarcentral   = ["1", "2", "3"]
    australiaeast  = ["1", "2", "3"]
    southeastasia  = ["1", "2", "3"]
    eastasia       = ["1", "2", "3"]
    japaneast      = ["1", "2", "3"]
    koreacentral   = ["1", "2", "3"]
    centralindia   = ["1", "2", "3"]
  }
}

# =============================================================================
# AWS Provider configurations
# =============================================================================

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "us-east-2"
  region = "us-east-2"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "us-west-1"
  region = "us-west-1"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "us-west-2"
  region = "us-west-2"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "ca-central-1"
  region = "ca-central-1"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "eu-west-1"
  region = "eu-west-1"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "eu-west-2"
  region = "eu-west-2"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "eu-west-3"
  region = "eu-west-3"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "eu-central-1"
  region = "eu-central-1"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "eu-north-1"
  region = "eu-north-1"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "ap-south-1"
  region = "ap-south-1"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "ap-northeast-1"
  region = "ap-northeast-1"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "ap-northeast-2"
  region = "ap-northeast-2"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "ap-northeast-3"
  region = "ap-northeast-3"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "ap-southeast-1"
  region = "ap-southeast-1"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "ap-southeast-2"
  region = "ap-southeast-2"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

provider "aws" {
  alias  = "sa-east-1"
  region = "sa-east-1"
  default_tags { tags = local.common_tags }
  skip_credentials_validation = var.enable_aws ? false : true
  skip_requesting_account_id  = var.enable_aws ? false : true
  skip_metadata_api_check     = var.enable_aws ? false : true
}

# =============================================================================
# Azure Provider configuration
# =============================================================================

provider "azurerm" {
  features {}
  skip_provider_registration = true

  # When Azure is disabled, use dummy values to prevent authentication errors
  # These fake credentials won't be used since no Azure resources are created
  subscription_id = var.enable_azure ? null : "00000000-0000-0000-0000-000000000000"
  tenant_id       = var.enable_azure ? null : "00000000-0000-0000-0000-000000000000"
  client_id       = var.enable_azure ? null : "00000000-0000-0000-0000-000000000000"
  client_secret   = var.enable_azure ? null : "disabled"
  use_cli         = var.enable_azure
  use_oidc        = false
  use_msi         = false
}

# =============================================================================
# AWS Module deployments
# =============================================================================

module "aws_us_east_1" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.us-east-1 }
}

module "aws_us_east_2" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.us-east-2 }
}

module "aws_us_west_1" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.us-west-1 }
}

module "aws_us_west_2" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.us-west-2 }
}

module "aws_ca_central_1" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.ca-central-1 }
}

module "aws_eu_west_1" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.eu-west-1 }
}

module "aws_eu_west_2" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.eu-west-2 }
}

module "aws_eu_west_3" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.eu-west-3 }
}

module "aws_eu_central_1" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.eu-central-1 }
}

module "aws_eu_north_1" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.eu-north-1 }
}

module "aws_ap_south_1" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.ap-south-1 }
}

module "aws_ap_northeast_1" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.ap-northeast-1 }
}

module "aws_ap_northeast_2" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.ap-northeast-2 }
}

module "aws_ap_northeast_3" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.ap-northeast-3 }
}

module "aws_ap_southeast_1" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.ap-southeast-1 }
}

module "aws_ap_southeast_2" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.ap-southeast-2 }
}

module "aws_sa_east_1" {
  count         = var.enable_aws ? 1 : 0
  source        = "./modules/aws-region"
  key_name      = var.aws_key_name
  public_key    = var.aws_public_key
  instance_type = var.aws_instance_type
  project_name  = local.project_name
  providers     = { aws = aws.sa-east-1 }
}

# =============================================================================
# Azure Module deployments
# =============================================================================

module "azure_eastus" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "eastus"
  zones          = local.azure_regions["eastus"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_eastus2" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "eastus2"
  zones          = local.azure_regions["eastus2"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_westus2" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "westus2"
  zones          = local.azure_regions["westus2"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_westus3" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "westus3"
  zones          = local.azure_regions["westus3"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_centralus" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "centralus"
  zones          = local.azure_regions["centralus"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_southcentralus" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "southcentralus"
  zones          = local.azure_regions["southcentralus"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_canadacentral" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "canadacentral"
  zones          = local.azure_regions["canadacentral"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_brazilsouth" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "brazilsouth"
  zones          = local.azure_regions["brazilsouth"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_uksouth" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "uksouth"
  zones          = local.azure_regions["uksouth"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_westeurope" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "westeurope"
  zones          = local.azure_regions["westeurope"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_northeurope" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "northeurope"
  zones          = local.azure_regions["northeurope"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_francecentral" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "francecentral"
  zones          = local.azure_regions["francecentral"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_germanywestcentral" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "germanywestcentral"
  zones          = local.azure_regions["germanywestcentral"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_norwayeast" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "norwayeast"
  zones          = local.azure_regions["norwayeast"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_swedencentral" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "swedencentral"
  zones          = local.azure_regions["swedencentral"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_switzerlandnorth" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "switzerlandnorth"
  zones          = local.azure_regions["switzerlandnorth"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_uaenorth" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "uaenorth"
  zones          = local.azure_regions["uaenorth"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_southafricanorth" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "southafricanorth"
  zones          = local.azure_regions["southafricanorth"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_qatarcentral" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "qatarcentral"
  zones          = local.azure_regions["qatarcentral"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_australiaeast" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "australiaeast"
  zones          = local.azure_regions["australiaeast"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_southeastasia" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "southeastasia"
  zones          = local.azure_regions["southeastasia"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_eastasia" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "eastasia"
  zones          = local.azure_regions["eastasia"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_japaneast" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "japaneast"
  zones          = local.azure_regions["japaneast"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_koreacentral" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "koreacentral"
  zones          = local.azure_regions["koreacentral"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

module "azure_centralindia" {
  count          = var.enable_azure ? 1 : 0
  source         = "./modules/azure-region"
  region         = "centralindia"
  zones          = local.azure_regions["centralindia"]
  vm_size        = var.azure_vm_size
  project_name   = local.project_name
  admin_username = var.azure_admin_username
  ssh_public_key = tls_private_key.azure_ssh[0].public_key_openssh
}

# =============================================================================
# Outputs
# =============================================================================

output "instances" {
  description = "All instances across all clouds and regions"
  value = merge(
    # AWS instances
    var.enable_aws ? module.aws_us_east_1[0].instances : {},
    var.enable_aws ? module.aws_us_east_2[0].instances : {},
    var.enable_aws ? module.aws_us_west_1[0].instances : {},
    var.enable_aws ? module.aws_us_west_2[0].instances : {},
    var.enable_aws ? module.aws_ca_central_1[0].instances : {},
    var.enable_aws ? module.aws_eu_west_1[0].instances : {},
    var.enable_aws ? module.aws_eu_west_2[0].instances : {},
    var.enable_aws ? module.aws_eu_west_3[0].instances : {},
    var.enable_aws ? module.aws_eu_central_1[0].instances : {},
    var.enable_aws ? module.aws_eu_north_1[0].instances : {},
    var.enable_aws ? module.aws_ap_south_1[0].instances : {},
    var.enable_aws ? module.aws_ap_northeast_1[0].instances : {},
    var.enable_aws ? module.aws_ap_northeast_2[0].instances : {},
    var.enable_aws ? module.aws_ap_northeast_3[0].instances : {},
    var.enable_aws ? module.aws_ap_southeast_1[0].instances : {},
    var.enable_aws ? module.aws_ap_southeast_2[0].instances : {},
    var.enable_aws ? module.aws_sa_east_1[0].instances : {},
    # Azure instances
    var.enable_azure ? module.azure_eastus[0].instances : {},
    var.enable_azure ? module.azure_eastus2[0].instances : {},
    var.enable_azure ? module.azure_westus2[0].instances : {},
    var.enable_azure ? module.azure_westus3[0].instances : {},
    var.enable_azure ? module.azure_centralus[0].instances : {},
    var.enable_azure ? module.azure_southcentralus[0].instances : {},
    var.enable_azure ? module.azure_canadacentral[0].instances : {},
    var.enable_azure ? module.azure_brazilsouth[0].instances : {},
    var.enable_azure ? module.azure_uksouth[0].instances : {},
    var.enable_azure ? module.azure_westeurope[0].instances : {},
    var.enable_azure ? module.azure_northeurope[0].instances : {},
    var.enable_azure ? module.azure_francecentral[0].instances : {},
    var.enable_azure ? module.azure_germanywestcentral[0].instances : {},
    var.enable_azure ? module.azure_norwayeast[0].instances : {},
    var.enable_azure ? module.azure_swedencentral[0].instances : {},
    var.enable_azure ? module.azure_switzerlandnorth[0].instances : {},
    var.enable_azure ? module.azure_uaenorth[0].instances : {},
    var.enable_azure ? module.azure_southafricanorth[0].instances : {},
    var.enable_azure ? module.azure_qatarcentral[0].instances : {},
    var.enable_azure ? module.azure_australiaeast[0].instances : {},
    var.enable_azure ? module.azure_southeastasia[0].instances : {},
    var.enable_azure ? module.azure_eastasia[0].instances : {},
    var.enable_azure ? module.azure_japaneast[0].instances : {},
    var.enable_azure ? module.azure_koreacentral[0].instances : {},
    var.enable_azure ? module.azure_centralindia[0].instances : {},
  )
}

output "aws_regions" {
  value = var.enable_aws ? [
    "us-east-1", "us-east-2", "us-west-1", "us-west-2",
    "ca-central-1",
    "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1", "eu-north-1",
    "ap-south-1", "ap-northeast-1", "ap-northeast-2", "ap-northeast-3",
    "ap-southeast-1", "ap-southeast-2",
    "sa-east-1"
  ] : []
}

output "azure_regions" {
  value = var.enable_azure ? keys(local.azure_regions) : []
}

output "enabled_clouds" {
  value = compact([
    var.enable_aws ? "aws" : "",
    var.enable_azure ? "azure" : ""
  ])
}

output "azure_ssh_private_key" {
  description = "Private SSH key for Azure VMs - save this to a file for SSH access"
  value       = var.enable_azure ? tls_private_key.azure_ssh[0].private_key_pem : ""
  sensitive   = true
}
