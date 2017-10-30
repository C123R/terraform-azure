provider "azurerm" {
}

# Create a Resource Group

resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myResourceGroup"
    location = "East US"

    tags {
        environment = "Terraform Demo"
    }
}

# Create a Virtual Network

resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "East US"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags {
        environment = "Terraform Demo"
    }
}

# Create Subnet

resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "mySubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.2.0/24"
}


# Create Public IP

resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "East US"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    public_ip_address_allocation = "dynamic"

    tags {
        environment = "Terraform Demo"
    }
}

# Firewall for SSH port 22

resource "azurerm_network_security_group" "temyterraformpublicipnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "East US"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"
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

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_network_interface" "myterraformnic" {
    name                = "myNIC"
    location            = "East US"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags {
        environment = "Terraform Demo"
    }
}

resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myVM"
    location              = "East US"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myvm"
        admin_username = "cizi"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/cizi/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDL1EnJq2BhZqmI/wndLdpz+Z5Zt5EWUGITg61vJV7FXNcA6kpgl0fytUmv6lu/37ma0KfVMMRDRxeo+toz6Or3eKeil4FQ4XeBAsszyjRIP+Qag01NprXUIfPNOxaYfam+A3MoxsSqmboBHWjSxwfujrI44vw4ThwCeA+X9aDv/MbCE8GXNe/9JStHntJmCfPV/b7T5v3MXropiZqEJZ9bSrequdYOqHSqrvd7Jkn9y8DbU6+fScJ7ou/wo+EmuJfZzL7MSoR0OZ3DHEf5XUe35KoYpeQ1TvlSx4m+f2VijigdTlPCTf0//1HH+g8Tyuu0kurmRzVLBgYVtvYvoe6z cizi@Cizers-MacBook-Pro.local"
        }
    }

    tags {
        environment = "Terraform Demo"
    }
}