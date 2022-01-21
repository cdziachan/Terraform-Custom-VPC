variable "aws_region" {
  default = "us-west-1"
}

variable "env" {
  default = "Prod"
}

variable "public_subnet_cidrs" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "private_subnet_cidrs" {
  default = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]
}

variable "tags" {
  description = "mutual tags to be shared amongst resources in the repo"
  type        = map(any)
  default = {
    Account_ID  = "123456789"
    Owner       = "Cloud Engineering"
    Cost_Center = "106435"
    Tier        = "Networking"
  }
}
