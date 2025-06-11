
locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Name            = var.namespace
    owner           = var.owner
    created-by      = var.created-by
    sleep-at-night  = var.sleep-at-night
    ttl             = var.TTL
    se-region      = var.region
    terraform      = true
    purpose        = "SE Demostack"
  }
}


variable "region" {
  description = "The region to create resources."
  default     = "eu-west-2"
}

variable "namespace" {
  description = <<EOH
this is the differantiates different demostack deployment on the same subscription, everycluster should have a different value
EOH
  default     = "connectdemo"
}

variable "servers" {
  description = "The number of data servers (consul, nomad, etc)."
  default     = "3"
}

variable "workers" {
  description = "The number of nomad worker vms to create."
  default     = "3"
}


variable "fabio_url" {
  description = "The url download fabio."
  default     = "https://github.com/fabiolb/fabio/releases/download/v1.5.7/fabio-1.5.7-go1.9.2-linux_amd64"
}


variable "cni_version" {
  description = "The version of the CNI plugin for nomad."
  default     = "1.6.0"
}


variable "owner" {
  description = "Email address of the user responsible for lifecycle of cloud resources used for training."
}

variable "hashi_region" {
  description = "the region the owner belongs in.  e.g. NA-WEST-ENT, EU-CENTRAL"
  default = "EMEA"
}

variable "created-by" {
  description = "Tag used to identify resources created programmatically by Terraform"
  default     = "Terraform"
}

variable "sleep-at-night" {
  description = "Tag used by reaper to identify resources that can be shutdown at night"
  default     = true
}

variable "TTL" {
  description = "Hours after which resource expires, used by reaper. Do not use any unit. -1 is infinite."
  default     = "240"
}

variable "vpc_cidr_block" {
  description = "The top-level CIDR block for the VPC."
  default     = "10.1.0.0/16"
}

variable "cidr_blocks" {
  description = "The CIDR blocks to create the workstations in."
  default     = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
}

variable "zone_id" {
  description = "The Route 53 Zone ID for your FQDN"
  default     = ""
}

variable "public_key" {
  description = "The contents of the SSH public key to use for connecting to the cluster."
}

variable "enterprise" {
  description = "do you want to use the enterprise version of the binaries"
  default     = false
}

variable "vaultlicense" {
  description = "Enterprise License for Vault"
  default     = ""
}

variable "consullicense" {
  description = "Enterprise License for Consul"
  default     = ""
}

variable "nomadlicense" {
  description = "Enterprise License for Nomad"
  default     = ""
}



variable "instance_type_server" {
  description = "The type(size) of data servers (consul, nomad, etc)."
  default     = "t4g.xlarge"
}

variable "instance_type_worker" {
  description = "The type(size) of data workers (consul, nomad, etc)."
  default     = "t4g.xlarge"
}
variable "windows_instance_type_worker" {
  description = "The type(size) of data worker (consul, nomad, etc)."
  default     = "t3.medium"
}


variable "consul_gossip_key" {
  default = ""
}

variable "consul_master_token" {
  default = ""
}

variable "consul_join_tag_value" {
  default = ""
}

variable "nomad_gossip_key" {
  default = ""
}

variable "run_nomad_jobs" {
  default = "1"
}

variable "host_access_ip" {
  description = "CIDR blocks allowed to connect via SSH on port 22"
  default     = []
}

variable "primary_datacenter" {
  description = "the primary datacenter for mesh gateways"
  default     = ""
}


variable "f5_username" {
  description = "F5 username"
  default     = "admin"
}

variable "f5_password" {
  description = "F5 password"
  default     = "admin"
  sensitive = true
}

variable "f5_ami_search_name" {
  description = "BIG-IP AMI name to search for"
  type        = string
  default     = "F5 BIGIP-16.1.0* PAYG-Good 25Mbps*"
}

variable "postgres_username" {
  description = "Username that will be used to create the AWS Postgres instance"
  default     = "postgresql"
}

variable "postgres_password" {
  description = "Password that will be used to create the AWS Postgres instance"
  default     = "YourPwdShouldBeLongAndSecure!"
}

  variable "postgres_db_name" {
  description = "Db_name that will be used to create the AWS Postgres instance"
  default     = "postgress"
}

variable "mysql_username" {
  description = "Username that will be used to create the AWS mysql instance"
  default     = "foo"
}

variable "mysql_password" {
  description = "Password that will be used to create the AWS mysql instance"
  default     = "YourPwdShouldBeLongAndSecure!"
}

  variable "mysql_db_name" {
  description = "Db_name that will be used to create the AWS mysql instance"
  default     = "mydb"
}

variable "documentdb_master_username" {
  description = "Username that will be used to create the AWS Postgres instance"
  default     = "postgresql"
}

variable "documentdb_master__password" {
  description = "Password that will be used to create the AWS Postgres instance"
  default     = "YourPwdShouldBeLongAndSecure!"
}