variable "aws_region" {
  default = "us-west-1"
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
  description = "mutual tags for all resources"
  type        = map(any)
  default = {
    Owner  = "Cloud Engineering"
    Tier   = "Networking"
    Region = "us-west-1"
    Env    = "Prod"
    VPC    = "Prod-VPC"
  }
}
