
#Autor - Erick Bezerra de Medeiros

provider "azurerm" {
  features {}
  subscription_id = "1aa7849c-6a87-42ab-b40e-b9fef2cd4b97"
  tenant_id       = "8100553e-2209-4d6b-b431-0a90618d00da"
}

# Criação dos Resource Groups
resource "azurerm_resource_group" "eastus_rg" {
  name     = "eastus-rg"
  location = "East US"
}

resource "azurerm_resource_group" "brazilsouth_rg" {
  name     = "brazilsouth-rg"
  location = "Brazil South"
}

resource "azurerm_resource_group" "japaneast_rg" {
  name     = "japaneast-rg"
  location = "Japan East"
}

# Criação das VNets (Hub-Spoke)
resource "azurerm_virtual_network" "eastus_vnet" {
  name                = "eastus-vnet"
  location            = azurerm_resource_group.eastus_rg.location
  resource_group_name = azurerm_resource_group.eastus_rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_virtual_network" "brazilsouth_vnet" {
  name                = "brazilsouth-vnet"
  location            = azurerm_resource_group.brazilsouth_rg.location
  resource_group_name = azurerm_resource_group.brazilsouth_rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_virtual_network" "japaneast_vnet" {
  name                = "japaneast-vnet"
  location            = azurerm_resource_group.japaneast_rg.location
  resource_group_name = azurerm_resource_group.japaneast_rg.name
  address_space       = ["10.2.0.0/16"]
}

# Criação das Sub-redes Core em cada VNet
resource "azurerm_subnet" "eastus_core_subnet" {
  name                 = "core-subnet"
  resource_group_name  = azurerm_resource_group.eastus_rg.name
  virtual_network_name = azurerm_virtual_network.eastus_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "brazilsouth_core_subnet" {
  name                 = "core-subnet"
  resource_group_name  = azurerm_resource_group.brazilsouth_rg.name
  virtual_network_name = azurerm_virtual_network.brazilsouth_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "japaneast_core_subnet" {
  name                 = "core-subnet"
  resource_group_name  = azurerm_resource_group.japaneast_rg.name
  virtual_network_name = azurerm_virtual_network.japaneast_vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}

# Configuração de Peering entre as VNets (EastUS <-> BrazilSouth, EastUS <-> JapanEast)
resource "azurerm_virtual_network_peering" "eastus_to_brazilsouth_peering" {
  name                        = "eastus-to-brazilsouth-peering"
  resource_group_name         = azurerm_resource_group.eastus_rg.name
  virtual_network_name        = azurerm_virtual_network.eastus_vnet.name
  remote_virtual_network_id   = azurerm_virtual_network.brazilsouth_vnet.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "brazilsouth_to_eastus_peering" {
  name                        = "brazilsouth-to-eastus-peering"
  resource_group_name         = azurerm_resource_group.brazilsouth_rg.name
  virtual_network_name        = azurerm_virtual_network.brazilsouth_vnet.name
  remote_virtual_network_id   = azurerm_virtual_network.eastus_vnet.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "eastus_to_japaneast_peering" {
  name                        = "eastus-to-japaneast-peering"
  resource_group_name         = azurerm_resource_group.eastus_rg.name
  virtual_network_name        = azurerm_virtual_network.eastus_vnet.name
  remote_virtual_network_id   = azurerm_virtual_network.japaneast_vnet.id
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "japaneast_to_eastus_peering" {
  name                        = "japaneast-to-eastus-peering"
  resource_group_name         = azurerm_resource_group.japaneast_rg.name
  virtual_network_name        = azurerm_virtual_network.japaneast_vnet.name
  remote_virtual_network_id   = azurerm_virtual_network.eastus_vnet.id
  allow_virtual_network_access = true
}

####################### AD ###############################
# 🔹 Criando um IP Público 01
resource "azurerm_public_ip" "pip-publico" {
  name                = "pipsrv01"
  resource_group_name = azurerm_resource_group.eastus_rg.name
  location            = azurerm_resource_group.eastus_rg.location
  allocation_method   = "Static"  # Pode ser "Static" ou "Dynamic"
  sku                 = "Standard" # "Standard" mantém IP fixo mesmo se a VM desligar
}

# 🔹 Criando uma Interface de Rede (NIC) e associando o IP Público
resource "azurerm_network_interface" "nicsrv01" {
  name                = "my-nic"
  resource_group_name = azurerm_resource_group.eastus_rg.name
  location            = azurerm_resource_group.eastus_rg.location

  ip_configuration {
    name                          = "srv01-nic-config"
    subnet_id                     = azurerm_subnet.eastus_core_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-publico.id
  }
}

# 🔹 Criando uma Máquina Virtual (Windows)
resource "azurerm_windows_virtual_machine" "vm01" {
  name                = "VM-SRVAD01"
  resource_group_name = azurerm_resource_group.eastus_rg.name
  location            = azurerm_resource_group.eastus_rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "adminuser"
  admin_password      = "Deploy@124578#"  # ⚠️ Recomendado usar Azure Key Vault

  network_interface_ids = [azurerm_network_interface.nicsrv01.id]

  computer_name = "winvmname"  # 🔹 Nome do computador (máx. 15 caracteres)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# 🔹 Exibindo o IP Público no output
output "public_ip" {
  value = azurerm_public_ip.pip-publico.ip_address
}

# Liberação da porta 3389 (RDP)
resource "azurerm_network_security_group" "nsg" {
  name                = "nsg"
  location            = azurerm_resource_group.eastus_rg.location
  resource_group_name = azurerm_resource_group.eastus_rg.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "3389"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nicsrv01.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}


# 🔹 Criando uma Interface de Rede (NIC) 
resource "azurerm_network_interface" "nicsrv02" {
  name                = "my-nic_02"
  resource_group_name = azurerm_resource_group.brazilsouth_rg.name
  location            = azurerm_resource_group.brazilsouth_rg.location

  ip_configuration {
    name                          = "srv02-nic-config"
    subnet_id                     = azurerm_subnet.brazilsouth_core_subnet.id
    private_ip_address_allocation = "Dynamic"
    
  }
}

# 🔹 Criando uma Máquina Virtual (Windows)
resource "azurerm_windows_virtual_machine" "vm02" {
  name                = "VM-SRVAD02"
  resource_group_name = azurerm_resource_group.brazilsouth_rg.name
  location            = azurerm_resource_group.brazilsouth_rg.location
  size                = "Standard_B4ms"
  admin_username      = "adminuser"
  admin_password      = "Deploy@124578#"  # ⚠️ Recomendado usar Azure Key Vault

  network_interface_ids = [azurerm_network_interface.nicsrv02.id]

  computer_name = "srvad02"  # 🔹 Nome do computador (máx. 15 caracteres)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# Liberação da porta 3389 (RDP)
resource "azurerm_network_security_group" "nsg02" {
  name                = "nsg02"
  location            = azurerm_resource_group.brazilsouth_rg.location
  resource_group_name = azurerm_resource_group.brazilsouth_rg.name

  security_rule {
    name                       = "Allow-RDP"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "3389"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }
}

####################### WEB ###############################
# 🔹 Criando um IP Público 02
resource "azurerm_public_ip" "pipweb01" {
  name                = "pipweb01"
  resource_group_name = azurerm_resource_group.japaneast_rg.name
  location            = azurerm_resource_group.japaneast_rg.location
  allocation_method   = "Static"  # Pode ser "Static" ou "Dynamic"
  sku                 = "Standard" # "Standard" mantém IP fixo mesmo se a VM desligar
}

# 🔹 Criando uma Interface de Rede (NIC) e associando o IP Público
resource "azurerm_network_interface" "nicweb01" {
  name                = "nicweb01"
  resource_group_name = azurerm_resource_group.japaneast_rg.name
  location            = azurerm_resource_group.japaneast_rg.location

  ip_configuration {
    name                          = "web01-nic-config"
    subnet_id                     = azurerm_subnet.japaneast_core_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pipweb01.id
  }
}

# 🔹 Criando uma Máquina Virtual (Windows)
resource "azurerm_windows_virtual_machine" "vm03" {
  name                = "VM-WEB01"
  resource_group_name = azurerm_resource_group.japaneast_rg.name
  location            = azurerm_resource_group.japaneast_rg.location
  size                = "Standard_B2ms"
  admin_username      = "adminuser"
  admin_password      = "Deploy@124578#"  # ⚠️ Recomendado usar Azure Key Vault

  network_interface_ids = [azurerm_network_interface.nicweb01.id]
  #network_interface_ids = [azurerm_network_interface.nicsrv02.id]

  computer_name = "vmweb01"  # 🔹 Nome do computador (máx. 15 caracteres)

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-Datacenter"
    version   = "latest"
  }
}

# 🔹 Exibindo o IP Público 02 no output
output "pipweb01" {
  value = azurerm_public_ip.pipweb01.ip_address
}

# Liberação da porta 80 (HTTP)
resource "azurerm_network_security_group" "nsgweb" {
  name                = "nsgweb"
  location            = azurerm_resource_group.japaneast_rg.location
  resource_group_name = azurerm_resource_group.japaneast_rg.name

  security_rule {
    name                       = "Allow-Http"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                  = "Tcp"
    source_port_range         = "*"
    destination_port_range    = "80"
    source_address_prefix     = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc02" {
  network_interface_id      = azurerm_network_interface.nicweb01.id
  network_security_group_id = azurerm_network_security_group.nsgweb.id
}