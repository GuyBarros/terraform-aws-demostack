
terraform {
  required_providers {
    aws = {
      version = "= 2.70.0"
    }
    template = {
      version = "~>2.2.0"
    }

    tls = {
      version = "~>3.1.0"
    }
  }
  required_version = ">= 1.0"
}