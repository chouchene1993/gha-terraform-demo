provider "azurerm" {
  version = ">=2.0"
  # The "feature" block is required for AzureRM provider 2.x.
  features {}
}

terraform {
 backend "azurerm" {
    
    resource_group_name  = "RG-Terraform"
    storage_account_name = "statfstaste1993"
    container_name       = "tfstate"
    key                  = "remotebackend.tfstate"

  }
}


data "azurerm_subscription" "current" {}

data "azurerm_storage_account" "sta" {
  name                = "statfstaste1993"
  resource_group_name = "RG-Terraform"
}

output "storage_account_tier" {
  value = data.azurerm_storage_account.sta.account_tier
}


resource "azurerm_resource_group" "rg" {
  name     = "RG-GHA"
  location = "francecentral"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "VNET-Dev"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.5.0.0/16"]
}

resource "azurerm_subnet" "service" {
  name                 = "sub-service"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.5.1.0/24"]

  enforce_private_link_service_network_policies = true
}

resource "azurerm_subnet" "endpoint" {
  name                 = "sub-endpoint"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.5.2.0/24"]

  enforce_private_link_endpoint_network_policies = true
}


resource "azurerm_storage_account" "funcsta" {
  name                     = "linfuncappsa19931216"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "asp" {
  name                = "func-app-service-plan"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_function_app" "func" {
  name                = "lin-fun-app-19931216"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  storage_account_name       = azurerm_storage_account.funcsta.name
  storage_account_access_key = azurerm_storage_account.funcsta.primary_access_key
  service_plan_id            = azurerm_service_plan.asp.id

  site_config {}
}

resource "azurerm_private_endpoint" "pe" {
  name                = "pe-privatelink"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.endpoint.id

  private_service_connection {
    name                           = azurerm_linux_function_app.func.name
    is_manual_connection           = false
    private_connection_resource_id = azurerm_linux_function_app.func.id
    subresource_names              = ["sites"]
  }
}
