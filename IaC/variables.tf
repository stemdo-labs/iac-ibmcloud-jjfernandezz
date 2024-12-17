variable "api_key" {
    type = string
    sensitive = true
}

variable "ssh_key" {
    type = string
    sensitive = true
    default = "~/.ssh/id_rsa.pub"
}

variable "resource_group" {
    type = string
    sensitive = true
}