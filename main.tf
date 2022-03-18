

provider "aws" {
  #  region  = var.primary_region
  #  alias   = "primary"
  default_tags {
    tags = local.common_tags
  }
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
  cni_plugin_url       = var.cni_plugin_url
  created-by           = var.created-by
  sleep-at-night       = var.sleep-at-night
  TTL                  = var.TTL
  vpc_cidr_block       = var.vpc_cidr_block
  cidr_blocks          = var.cidr_blocks
  instance_type_server = var.instance_type_server
  instance_type_worker = var.instance_type_worker
  zone_id              = data.terraform_remote_state.dns.outputs.aws_sub_zone_id
  run_nomad_jobs       = var.run_nomad_jobs
  host_access_ip       = var.host_access_ip
  primary_datacenter   = each.value.namespace

  # EMEA-SE-PLAYGROUND
  ca_key_algorithm      = data.terraform_remote_state.tls.outputs.ca_key_algorithm
  ca_private_key_pem    = data.terraform_remote_state.tls.outputs.ca_private_key_pem
  ca_cert_pem           = data.terraform_remote_state.tls.outputs.ca_cert_pem
  consul_join_tag_value = "${each.value.namespace}-${data.terraform_remote_state.tls.outputs.consul_join_tag_value}"
  consul_gossip_key     = data.terraform_remote_state.tls.outputs.consul_gossip_key
  #consul_master_token   = data.terraform_remote_state.tls.outputs.consul_master_token
  #consul_master_token   = "5fder467-5gf5-8ju7-1q2w-y6gj78kl9gfd"
  consul_master_token = uuid()
  nomad_gossip_key    = data.terraform_remote_state.tls.outputs.nomad_gossip_key
}
