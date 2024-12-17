terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
    }
  }
}

# Configure the IBM Provider
provider "ibm" {
  region = "eu-gb"
  ibmcloud_api_key = var.api_key
}

# Create a IS VPC and instance
resource "ibm_is_vpc" "joel_vpc" {
  name = "joel-vpc"
  resource_group = var.resource_group
}

resource "ibm_is_subnet" "joel_subnet" {
  name            = "joel-subnet"
  vpc             = ibm_is_vpc.joel_vpc.id
  zone            = "eu-gb-1"
  ipv4_cidr_block = "10.10.0.0/24"
  resource_group = var.resource_group
}

resource "ibm_is_security_group" "joel_security_group" {
  name            = "joel-security-group"
  vpc          =  ibm_is_vpc.joel_vpc.id  
  resource_group  = var.resource_group         
}

resource "ibm_is_security_group_rule" "rule_ssh" {
  group     = ibm_is_security_group.joel_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_ssh_key" "joel_sshkey" {
  name       = "joel-ssh"
  public_key = file(var.ssh_key)
}

resource "ibm_is_instance" "joel_instance" {
  name    = "joel-instance"
  image   = ""
  profile = "bx2-2x8"
  resource_group = var.resource_group

  primary_network_interface {
    subnet = ibm_is_subnet.joel_subnet.id
  }

  vpc       = ibm_is_vpc.joel_vpc.id
  zone      = "eu-gb-1"
  keys      = [ibm_is_ssh_key.joel_sshkey.id]
}

resource "ibm_is_floating_ip" "joel_floatingip" {
  name   = "joel-fip"
  target = ibm_is_instance.joel_instance.primary_network_interface[0].id
}

##### Cluster 

resource "ibm_is_vpc" "joel_vpc_cluster" {
  name = "joel-vpc-cluster"
  resource_group = var.resource_group
}

resource "ibm_is_subnet" "joel_subnet_cluster" {
  name            = "joel-subnet-cluster"
  vpc             = ibm_is_vpc.joel_vpc_cluster.id
  zone            = "eu-gb-1"
  ipv4_cidr_block = "10.50.0.0/24"
  resource_group = var.resource_group
}

resource "ibm_container_cluster" "joel_cluster" {
  name = "joel-cluster"
  datacenter = "eu-gb-1"
  machine_type    = "b3c.4x16"
  hardware  = "shared"
  kube_version = "4.3_openshift"
  subnet_id = [ibm_is_subnet.joel_subnet_cluster.id]

  default_pool_size = 1
}