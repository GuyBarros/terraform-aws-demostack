

provider "aws" {
  #  region  = var.primary_region
  #  alias   = "primary"
   # default_tags {
   #   tags = local.common_tags
  #  }
}



module "cluster" {
  source               = "./modules"
  for_each             = var.clusters
  owner                = var.owner
  region               = each.value.region
  namespace            = each.value.namespace
  public_key           = var.public_key
  servers              = var.servers
  workers              = var.workers
  vaultlicense         = var.vaultlicense
  consullicense        = var.consullicense
  nomadlicense         = var.nomadlicense
  enterprise           = var.enterprise
  fabio_url            = var.fabio_url
  cni_version       = var.cni_version
  created-by           = var.created-by
  sleep-at-night       = var.sleep-at-night
  TTL                  = var.TTL
  vpc_cidr_block       = var.vpc_cidr_block
  cidr_blocks          = var.cidr_blocks
  instance_type_server = var.instance_type_server
  instance_type_worker = var.instance_type_worker
  zone_id              = var.zone_id
  run_nomad_jobs       = var.run_nomad_jobs
  host_access_ip       = var.host_access_ip
  primary_datacenter   = each.value.namespace

  # EMEA-SE-PLAYGROUND
  consul_join_tag_value = "${each.value.namespace}-${random_id.consul_join_tag_value.hex}"
  consul_gossip_key     = random_id.consul_gossip_key.hex
  #consul_master_token   = data.terraform_remote_state.tls.outputs.consul_master_token
  #consul_master_token   = "5fder467-5gf5-8ju7-1q2w-y6gj78kl9gfd"
  consul_master_token = uuid()
  nomad_gossip_key    = random_id.nomad_gossip_key.hex

  #F5 Creds
  f5_username = var.f5_username
  f5_password = var.f5_password
}

# Consul gossip encryption key
resource "random_id" "consul_gossip_key" {
  byte_length = 16
}

# Consul master token
resource "random_id" "consul_master_token" {
  byte_length = 16
}

# Consul join key
resource "random_id" "consul_join_tag_value" {
  byte_length = 16
}

# Nomad gossip encryption key
resource "random_id" "nomad_gossip_key" {
  byte_length = 16
}