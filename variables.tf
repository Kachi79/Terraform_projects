
variable "region" {
      default = "us-west-2"
}

variable "vpc_cidr" {
    default = "10.0.0.0/16"
}

variable "enable_dns_support" {
    default = "true"
}

variable "enable_dns_hostnames" {
    default ="true" 
}


  variable "preferred_number_of_public_subnets" {
    type = number
    description = "Number of public subnets" 
}

  variable "preferred_number_of_private_subnets" {
    type = number 
    description = "Number of private subnets"
}
