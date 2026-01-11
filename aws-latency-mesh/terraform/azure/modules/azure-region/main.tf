# modules/azure-region/main.tf
# Deploys one VM per availability zone in an Azure region for latency measurement

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

variable "region" {
  description = "Azure region name"
  type        = string
}

variable "zones" {
  description = "List of availability zones in this region"
  type        = list(string)
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "latency-mesh"
}

variable "admin_username" {
  description = "Admin username for VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "SSH public key (from tls_private_key)"
  type        = string
}

# Resource Group
resource "azurerm_resource_group" "latency_test" {
  name     = "${var.project_name}-${var.region}-rg"
  location = var.region

  tags = {
    Project   = "latency-measurement"
    ManagedBy = "terraform"
    Cloud     = "azure"
  }
}

# Virtual Network
resource "azurerm_virtual_network" "latency_test" {
  name                = "${var.project_name}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.latency_test.location
  resource_group_name = azurerm_resource_group.latency_test.name

  tags = {
    Name = "${var.project_name}-vnet"
  }
}

# Subnet per zone
resource "azurerm_subnet" "latency_test" {
  for_each = toset(var.zones)

  name                 = "${var.project_name}-subnet-zone${each.key}"
  resource_group_name  = azurerm_resource_group.latency_test.name
  virtual_network_name = azurerm_virtual_network.latency_test.name
  address_prefixes     = [cidrsubnet("10.0.0.0/16", 8, tonumber(each.key))]
}

# Network Security Group
resource "azurerm_network_security_group" "latency_test" {
  name                = "${var.project_name}-nsg"
  location            = azurerm_resource_group.latency_test.location
  resource_group_name = azurerm_resource_group.latency_test.name

  # SSH access
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ICMP (ping)
  security_rule {
    name                       = "ICMP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # iperf3
  security_rule {
    name                       = "iperf3"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5201"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # qperf
  security_rule {
    name                       = "qperf"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "19765-19766"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Name = "${var.project_name}-nsg"
  }
}

# Public IP per zone
resource "azurerm_public_ip" "latency_test" {
  for_each = toset(var.zones)

  name                = "${var.project_name}-pip-zone${each.key}"
  location            = azurerm_resource_group.latency_test.location
  resource_group_name = azurerm_resource_group.latency_test.name
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [each.key]

  tags = {
    Name = "${var.project_name}-pip-zone${each.key}"
    Zone = each.key
  }
}

# Network Interface per zone
resource "azurerm_network_interface" "latency_test" {
  for_each = toset(var.zones)

  name                           = "${var.project_name}-nic-zone${each.key}"
  location                       = azurerm_resource_group.latency_test.location
  resource_group_name            = azurerm_resource_group.latency_test.name
  accelerated_networking_enabled = true  # Reduces latency by bypassing host networking stack

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.latency_test[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.latency_test[each.key].id
  }

  tags = {
    Name = "${var.project_name}-nic-zone${each.key}"
    Zone = each.key
  }
}

# Associate NSG with NICs
resource "azurerm_network_interface_security_group_association" "latency_test" {
  for_each = toset(var.zones)

  network_interface_id      = azurerm_network_interface.latency_test[each.key].id
  network_security_group_id = azurerm_network_security_group.latency_test.id
}

# User data script (cloud-init)
locals {
  user_data = <<-EOF
    #cloud-config
    package_update: true
    packages:
      - iperf3
      - qperf
      - bind-utils
      - jq

    write_files:
      - path: /home/${var.admin_username}/measure_latency.sh
        permissions: '0755'
        owner: ${var.admin_username}:${var.admin_username}
        content: |
          #!/bin/bash
          TARGET_IP=$1
          TARGET_ZONE=$2
          SOURCE_ZONE=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance/compute/zone?api-version=2021-02-01&format=text")

          # Run ping test (100 packets)
          PING_RESULT=$(ping -c 100 -i 0.1 $TARGET_IP 2>/dev/null | tail -1)

          # Parse results
          if [[ $PING_RESULT =~ ([0-9.]+)/([0-9.]+)/([0-9.]+)/([0-9.]+) ]]; then
              MIN=$${BASH_REMATCH[1]}
              AVG=$${BASH_REMATCH[2]}
              MAX=$${BASH_REMATCH[3]}
              MDEV=$${BASH_REMATCH[4]}
          else
              MIN="N/A"
              AVG="N/A"
              MAX="N/A"
              MDEV="N/A"
          fi

          echo "{\"source_zone\":\"$SOURCE_ZONE\",\"target_zone\":\"$TARGET_ZONE\",\"target_ip\":\"$TARGET_IP\",\"min_ms\":\"$MIN\",\"avg_ms\":\"$AVG\",\"max_ms\":\"$MAX\",\"mdev_ms\":\"$MDEV\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
  EOF
}

# Linux VM per zone
resource "azurerm_linux_virtual_machine" "latency_node" {
  for_each = toset(var.zones)

  name                = "${var.project_name}-vm-zone${each.key}"
  resource_group_name = azurerm_resource_group.latency_test.name
  location            = azurerm_resource_group.latency_test.location
  size                = var.vm_size
  zone                = each.key
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.latency_test[each.key].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = trimspace(var.ssh_public_key)
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(local.user_data)

  tags = {
    Name   = "${var.project_name}-zone${each.key}"
    Zone   = each.key
    Region = var.region
  }

  lifecycle {
    ignore_changes = [admin_ssh_key]
  }
}

# Outputs
output "instances" {
  value = {
    for zone in var.zones : "${var.region}-zone${zone}" => {
      instance_id = azurerm_linux_virtual_machine.latency_node[zone].id
      private_ip  = azurerm_network_interface.latency_test[zone].private_ip_address
      public_ip   = azurerm_public_ip.latency_test[zone].ip_address
      az_id       = zone
      az_name     = "${var.region}-zone${zone}"
      region      = var.region
      cloud       = "azure"
    }
  }
}

output "region" {
  value = var.region
}

output "zone_count" {
  value = length(var.zones)
}
