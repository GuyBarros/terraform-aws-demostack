variable "region" {
  description = "The region to create resources."
  default     = "eu-west-2"
}

variable "namespace" {
  description = <<EOH
this is the differantiates different demostack deployment on the same subscription, everycluster should have a different value
EOH
  default = "primarystack"
}

variable "primary_namespace" {
    description = <<EOH
this is the differantiates different demostack deployment on the same subscription, everycluster should have a different value
EOH

default = "primarystack"
}

variable "secondary_namespace" {
  description = <<EOH
this is the differantiates different demostack deployment on the same subscription, everycluster should have a different value
EOH

default = "secondarystack"
}

variable "tertiary_namespace" {
  description = <<EOH
this is the differantiates different demostack deployment on the same subscription, everycluster should have a different value
EOH

default = "tertiarystack"
}

variable "primary_region" {
  description = "The region to create resources."
  default = "eu-west-2"
}

variable "secondary_region" {
  description = "The region to create resources."
  default = "eu-west-2"
}

variable "tertiary_region" {
  description = "The region to create resources."
  default = "ap-northeast-1"
}


variable "servers" {
  description = "The number of data servers (consul, nomad, etc)."
  default = "3"
}

variable "workers" {
  description = "The number of nomad worker vms to create."
  default = "3"
}

variable "consul_url" {
  description = "The url to download Consul."
  default = "https://releases.hashicorp.com/consul/1.2.2/consul_1.2.2_linux_amd64.zip"
}

variable "consul_ent_url" {
  description = "The url to download Consul."
  default = "https://releases.hashicorp.com/consul/1.2.2/consul_1.2.2_linux_amd64.zip"
}

variable "fabio_url" {
  description = "The url download fabio."
  default = "https://github.com/fabiolb/fabio/releases/download/v1.5.7/fabio-1.5.7-go1.9.2-linux_amd64"
}

variable "hashiui_url" {
  description = "The url to download hashi-ui."
  default = "https://github.com/jippi/hashi-ui/releases/download/v0.26.1/hashi-ui-linux-amd64"
}

variable "nomad_url" {
  description = "The url to download nomad."
  default = "https://releases.hashicorp.com/nomad/0.8.4/nomad_0.8.4_linux_amd64.zip"
}

variable "nomad_ent_url" {
  description = "The url to download nomad."
  default = "https://releases.hashicorp.com/nomad/0.8.4/nomad_0.8.4_linux_amd64.zip"
}

variable "vault_url" {
  description = "The url to download vault."
  default = "https://releases.hashicorp.com/vault/0.11.1/vault_0.11.1_linux_amd64.zip"
}

variable "vault_ent_url" {
  description = "The url to download vault."
  default = "https://s3-us-west-2.amazonaws.com/hc-enterprise-binaries/vault/ent/0.11.1/vault-enterprise_0.11.1%2Bent_linux_amd64.zip"
}

variable "owner" {
description = "IAM user responsible for lifecycle of cloud resources used for training"
}

variable "created-by" {
description = "Tag used to identify resources created programmatically by Terraform"
default = "Terraform"
}

variable "sleep-at-night" {
description = "Tag used by reaper to identify resources that can be shutdown at night"
default = true
}

variable "TTL" {
description = "Hours after which resource expires, used by reaper. Do not use any unit. -1 is infinite."
default = "240"
}

variable "vpc_cidr_block" {
description = "The top-level CIDR block for the VPC."
default = "10.1.0.0/16"
}

variable "cidr_blocks" {
description = "The CIDR blocks to create the workstations in."
default = ["10.1.1.0/24", "10.1.2.0/24"]
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
default = false
}

variable "vaultlicense" {
description = "Enterprise License for Vault"
default = ""
}

variable "consullicense" {
description = "Enterprise License for Consul"
default = ""
}

variable "instance_type_server" {
description = "The type(size) of data servers (consul, nomad, etc)."
default = "r4.large"
}

variable "instance_type_worker" {
description = "The type(size) of data servers (consul, nomad, etc)."
default = "t2.medium"
}

variable "ca_key_algorithm" {
default = ""
}

variable "ca_private_key_pem" {
default = ""
}

variable "ca_cert_pem" {
default = ""
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
