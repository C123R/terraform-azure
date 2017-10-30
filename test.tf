provider "azurerm" {
}
resource "azurerm_resource_group" "test" {
        name = "testResourceGroup"
        location = "westus"
}
