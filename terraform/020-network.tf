#### NETWORK CONFIGURATION ####

#################
#### ROUTERS ####
#################

# This router will connect all MNAIO-related networks
# Connectivity to the management interfaces will be provided
# via Floating IPs. Same for deployed VMs (at some point).

resource "openstack_networking_router_v2" "mnaio-overcloud-router" {
  name                = "${join("-",["${random_pet.pet_name.id}","${var.overcloud_router.name}"])}"
  admin_state_up      = true
  external_network_id = var.external_network["uuid"]
  enable_snat         = true
}

#################################
#### MNAIO MANGEMENT NETWORK ####
#################################

resource "openstack_networking_network_v2" "mnaio-management" {
  name = "${join("-",["${random_pet.pet_name.id}","mnaio-management"])}"
}

resource "openstack_networking_subnet_v2" "mnaio-management" {
  name            = "${join("-",["${random_pet.pet_name.id}","${var.network_management["subnet_name"]}"])}"
  network_id      = openstack_networking_network_v2.mnaio-management.id
  cidr            = var.network_management["cidr"]
  dns_nameservers = var.dns_ip
}

resource "openstack_networking_router_interface_v2" "router-interface-mgmt" {
  router_id = "${openstack_networking_router_v2.mnaio-overcloud-router.id}"
  subnet_id = "${openstack_networking_subnet_v2.mnaio-management.id}"
}

#################################
#### MNAIO CONTAINER NETWORK ####
#################################

resource "openstack_networking_network_v2" "mnaio-container" {
  name = "${join("-",["${random_pet.pet_name.id}","mnaio-container"])}"
}

resource "openstack_networking_subnet_v2" "mnaio-container" {
  name            = "${join("-",["${random_pet.pet_name.id}","${var.network_container["subnet_name"]}"])}"
  network_id      = openstack_networking_network_v2.mnaio-container.id
  cidr            = var.network_container["cidr"]
  dns_nameservers = var.dns_ip
  no_gateway      = true
}

###############################
#### MNAIO OVERLAY NETWORK ####
###############################

resource "openstack_networking_network_v2" "mnaio-overlay" {
  name = "${join("-",["${random_pet.pet_name.id}","mnaio-overlay"])}"
}

resource "openstack_networking_subnet_v2" "mnaio-overlay" {
  name            = "${join("-",["${random_pet.pet_name.id}","${var.network_overlay["subnet_name"]}"])}"
  network_id      = openstack_networking_network_v2.mnaio-overlay.id
  cidr            = var.network_overlay["cidr"]
  dns_nameservers = var.dns_ip
  no_gateway      = true
}

###############################
#### MNAIO STORAGE NETWORK ####
###############################

resource "openstack_networking_network_v2" "mnaio-storage" {
  name = "${join("-",["${random_pet.pet_name.id}","mnaio-storage"])}"
}

resource "openstack_networking_subnet_v2" "mnaio-storage" {
  name            = "${join("-",["${random_pet.pet_name.id}","${var.network_storage["subnet_name"]}"])}"
  network_id      = openstack_networking_network_v2.mnaio-storage.id
  cidr            = var.network_storage["cidr"]
  dns_nameservers = var.dns_ip
  no_gateway      = true
}

###################################
#### MNAIO REPLICATION NETWORK ####
###################################

resource "openstack_networking_network_v2" "mnaio-replication" {
  name = "${join("-",["${random_pet.pet_name.id}","mnaio-replication"])}"
}

resource "openstack_networking_subnet_v2" "mnaio-replication" {
  name            = "${join("-",["${random_pet.pet_name.id}","${var.network_replication["subnet_name"]}"])}"
  network_id      = openstack_networking_network_v2.mnaio-replication.id
  cidr            = var.network_replication["cidr"]
  dns_nameservers = var.dns_ip
  no_gateway      = true
}

################################
#### MNAIO PROVIDER NETWORK ####
################################

# The goal here is to leverage an undercloud "tenant" network
# as an overcloud "provider" network. The overcloud provider
# network will be reachable from any overcloud node, as it will
# sit behind the same undercloud Neutron router. That router
# should provide outbound SNAT capabilities whether or not
# floating IPs are used by the overcloud.

resource "openstack_networking_network_v2" "mnaio-provider-ext" {
  name = "${join("-",["${random_pet.pet_name.id}","mnaio-provider-ext"])}"
  external = true
}

resource "openstack_networking_subnet_v2" "mnaio-provider-ext" {
  name            = "${join("-",["${random_pet.pet_name.id}","${var.network_provider["subnet_name"]}"])}"
  network_id      = openstack_networking_network_v2.mnaio-provider-ext.id
  cidr            = var.network_provider["cidr"]
  no_gateway      = true
  enable_dhcp     = false
}

resource "openstack_networking_port_v2" "mnaio-router-provider-port" {
  name           = "${join("-",["${random_pet.pet_name.id}","mnaio-router-provider-ext"])}"
  network_id     = openstack_networking_network_v2.mnaio-provider-ext.id
  fixed_ip {
    subnet_id    = openstack_networking_subnet_v2.mnaio-provider-ext.id
    ip_address   = "10.239.0.1"
  }
  no_security_groups        = true
  port_security_enabled     = false
  admin_state_up = "true"
}

resource "openstack_networking_router_interface_v2" "router-interface-provider-ext" {
  router_id = "${openstack_networking_router_v2.mnaio-overcloud-router.id}"
  port_id = "${openstack_networking_port_v2.mnaio-router-provider-port.id}"
}
