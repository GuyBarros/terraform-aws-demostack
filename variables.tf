
locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Name      = var.name
    owner     = var.owner
    se-region = var.se-region
    terraform = true
    purpose   = var.purpose
    ttl       = var.TTL
  }
}

variable "se-region" {
  description = "Mandatory tags for the SE organization"
}


variable "purpose" {
  description = <<EOH
purpose to be added to the default tags
EOH
}

variable "name" {
  description = <<EOH
Name to be added to the default tags
EOH
}


variable "host_access_ip" {
  description = "your IP address to allow ssh to work"
  default     = []
}

variable "clusters" {
  description = "Map of Cluster to deploy"
  type        = map(any)
  default = {
    primary = {
      region    = "eu-west-2"
      namespace = "primarystack"
    },
    secondary = {
      region    = "eu-east-1"
      namespace = "secondarystack"
    },
    tertiary = {
      region    = "ap-northeast-1"
      namespace = "tertiarystack"
    },
  }
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

variable "cni_plugin_url" {
  description = "The url to download teh CNI plugin for nomad."
  default     = "https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz"
}

variable "owner" {
  description = "IAM user responsible for lifecycle of cloud resources used for training"
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
  default     = ["10.1.1.0/24", "10.1.2.0/24",  "10.1.3.0/24"]
}

variable "zone_id" {
  description = "The CIDR blocks to create the workstations in."
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
  default     = "r4.large"
}

variable "instance_type_worker" {
  description = "The type(size) of data servers (consul, nomad, etc)."
  default     = "t2.medium"
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
  default = "0"
}


variable "primary_datacenter" {
  description = "the primary datacenter for mesh gateways"
  default     = ""
}

variable "dns-workspace-name" {
  description = "the workspace name to access dns configuration for this deployment"
}

variable "tls-workspace-name" {
  description = "the workspace name to access dns configuration for this deployment"
  default     = "tls-root-certificate"
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