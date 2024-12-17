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
  ipv4_cidr_block = "10.242.0.0/18"
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
  public_key = var.ssh_key
  type       = "rsa"
  resource_group = var.resource_group
}

resource "ibm_is_instance" "joel_instance" {
  name    = "joel-instance"
  image   = "r018-941eb02e-ceb9-44c8-895b-b31d241f43b5"
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
  resource_group = var.resource_group
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
  ipv4_cidr_block = "10.242.0.0/18"
  resource_group = var.resource_group
}

resource "ibm_resource_instance" "cos_instance" {
  name     = "joel-cos-instance"
  service  = "cloud-object-storage"
  plan     = "standard"
  location = "global"
  resource_group_id = var.resource_group
}

resource "ibm_container_vpc_cluster" "joel_cluster" {
  name              = "joel-vpc-cluster"
  vpc_id            = ibm_is_vpc.joel_vpc_cluster.id
  kube_version      = "4.16.23_openshift"
  flavor            = "bx2.16x64"
  worker_count      = "1"
  entitlement       = "cloud_pak"
  cos_instance_crn  = ibm_resource_instance.cos_instance.id
  resource_group_id = var.resource_group
  zones {
      subnet_id = ibm_is_subnet.joel_subnet_cluster.id
      name      = "eu-gb-1"
    }
}
