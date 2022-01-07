variable "aws_region" {
  default = "us-west-1"
}

variable "env" {
  default = "Prod"
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
