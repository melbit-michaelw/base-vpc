variable "name" {}

variable "env" {
    default = "prod"
}
variable "region" {
  default = "ap-southeast-2"
}

variable "azs" {
    default = ["ap-southeast-2a", "ap-southeast-2b", "ap-southeast-2c"]
}
variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "public_subnet_tier_cidr" {
    default = "10.0.0.0/22"
}

variable "num_azs" {
    default = 3
}

variable "nat_gw" {
    default = 0
}
