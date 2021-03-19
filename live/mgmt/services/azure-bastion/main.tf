terraform {
  # BUG(medium) no locking
  backend "s3" {
    bucket = "terraform.aws.jeremychase.io"
    key    = "live/mgmt/services/azure-bastion"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.14.0"
    }

    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.46.0"
    }
  }

}

provider "azurerm" {
  features {}
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic1"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "primary"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_interface" "internal" {
  name                = "${var.prefix}-nic2"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_B1S"
  admin_username                  = var.adminuser
  disable_password_authentication = true

  admin_ssh_key {
    username = var.adminuser
    public_key = file(var.adminuser_pubkey)
  }

  network_interface_ids = [
    azurerm_network_interface.main.id,
    azurerm_network_interface.internal.id,
  ]

  source_image_reference {
    publisher     = "Debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "StandardSSD_LRS"
    caching              = "ReadWrite"
    disk_size_gb         = 64
  }
}

data "aws_route53_zone" "selected" {
  name = "${var.zone_name}."
}

resource "aws_route53_record" "pip_a" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.location}.aws.${var.zone_name}."
  records = [
    azurerm_public_ip.pip.ip_address,
  ]
  ttl  = 300
  type = "A"
}

resource "aws_route53_record" "short_cname" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "azure.${var.zone_name}."
  records = [
    aws_route53_record.pip_a.name,
  ]
  ttl  = 300
  type = "CNAME"
}
