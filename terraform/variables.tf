variable region {
    default = "eu-central-1"
}

variable "environment" {
  description = "environment to deploy"
  default = "development"
}

variable "env_prefix" {
  description = "environment prefix resource"
  type = string
  default = "dev"
}

variable vpc_cidr_block {
    default = "10.0.0.0/16"
}

variable subnet_cidr_block {
    default = "10.0.10.0/24"
}

variable avail_zone {
    default = "eu-central-1a"
}

variable my_ip {
    default = "198.184.231.254/32"
}

variable instance_type {
    default = "t2.micro"
}
