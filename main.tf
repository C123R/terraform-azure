module "child" {
  source = "./child"
}

provider "azurerm" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group}"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.virtual_network_name}"
  location            = "${var.location}"
  address_space       = ["${var.address_space}"]
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.rg_prefix}subnet"
  virtual_network_name = "${azurerm_virtual_network.vnet.name}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  address_prefix       = "${var.subnet_prefix}"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.rg_prefix}nic"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  ip_configuration {
    name                          = "${var.rg_prefix}ipconfig"
    subnet_id                     = "${azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.pip.id}"
  }
}

resource "azurerm_public_ip" "pip" {
  name                         = "${var.rg_prefix}-ip"
  location                     = "${var.location}"
  resource_group_name          = "${azurerm_resource_group.rg.name}"
  public_ip_address_allocation = "Dynamic"
  domain_name_label            = "${var.dns_name}"
}

resource "azurerm_storage_account" "stor" {
  name                     = "${var.dns_name}stor"
  location                 = "${var.location}"
  resource_group_name      = "${azurerm_resource_group.rg.name}"
  account_tier             = "${var.storage_account_tier}"
  account_replication_type = "${var.storage_replication_type}"
}

resource "azurerm_managed_disk" "datadisk" {
  name                 = "${var.hostname}-datadisk"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_redis_cache" "rediscache" {
  name                = "test"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  capacity            = 0
  family              = "C"
  sku_name            = "Basic"
  enable_non_ssl_port = false

  redis_configuration {
    maxclients = 256
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "${var.rg_prefix}vm"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  vm_size               = "${var.vm_size}"
  network_interface_ids = ["${azurerm_network_interface.nic.id}"]

  storage_image_reference {
    publisher = "${var.image_publisher}"
    offer     = "${var.image_offer}"
    sku       = "${var.image_sku}"
    version   = "${var.image_version}"
  }

  storage_os_disk {
    name              = "${var.hostname}-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "${var.hostname}"
    admin_username = "${var.admin_username}"
  }

  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/cizi/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDL1EnJq2BhZqmI/wndLdpz+Z5Zt5EWUGITg61vJV7FXNcA6kpgl0fytUmv6lu/37ma0KfVMMRDRxeo+toz6Or3eKeil4FQ4XeBAsszyjRIP+Qag01NprXUIfPNOxaYfam+A3MoxsSqmboBHWjSxwfujrI44vw4ThwCeA+X9aDv/MbCE8GXNe/9JStHntJmCfPV/b7T5v3MXropiZqEJZ9bSrequdYOqHSqrvd7Jkn9y8DbU6+fScJ7ou/wo+EmuJfZzL7MSoR0OZ3DHEf5XUe35KoYpeQ1TvlSx4m+f2VijigdTlPCTf0//1HH+g8Tyuu0kurmRzVLBgYVtvYvoe6z cizi@Cizers-MacBook-Pro.local"
    }
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = "${azurerm_storage_account.stor.primary_blob_endpoint}"
  }

  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.pip.fqdn} >> hosts && ansible-playbook --extra-vars ${azurerm_public_ip.pip.fqdn} docker.yml"
  }
}
