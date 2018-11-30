provider "aws" {
  version = ">= 1.20.0"
  region  = "${var.primary_region}"
}


module "primarycluster" {
  source              = "./modules"
  owner               = "${var.owner}"
  region              = "${var.primary_region}"
  namespace           = "${var.primary_namespace}"
  public_key          = "${var.public_key}"
  demo_username       = "${var.demo_username}"
  demo_password       = "${var.demo_password}"
  servers             = "${var.servers}"
  nomadworkers        = "${var.nomadworkers}"
  vaultlicense        = "${var.vaultlicense}"
  consullicense       = "${var.consullicense}"
  enterprise          = "${var.enterprise}"
  consul_url          = "${var.consul_url}"
  consul_ent_url      = "${var.consul_ent_url}"
  packer_url          = "${var.packer_url}"
  sentinel_url        = "${var.sentinel_url}"
  consul_template_url = "${var.consul_template_url}"
  envconsul_url       = "${var.envconsul_url}"
  fabio_url           = "${var.fabio_url}"
  hashiui_url         = "${var.hashiui_url}"
  nomad_url           = "${var.nomad_url}"
  nomad_ent_url       = "${var.nomad_ent_url}"
  terraform_url       = "${var.terraform_url}"
  vault_url           = "${var.vault_url}"
  vault_ent_url       = "${var.vault_ent_url}"
  created-by          = "${var.created-by}"
  sleep-at-night      = "${var.sleep-at-night}"
  TTL                 = "${var.TTL}"
  vpc_cidr_block      = "${var.vpc_cidr_block}"
  cidr_blocks         = "${var.cidr_blocks}"
  instance_type_server= "${var.instance_type_server}"
  instance_type_worker= "${var.instance_type_worker}"
  ca_key_algorithm   = "${tls_private_key.root.algorithm}"
  ca_private_key_pem = "${tls_private_key.root.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.root.cert_pem}"
}

/*
module "secondarycluster" {
  source              = "./modules"
  owner               = "${var.owner}"
  region              = "${var.secondary_region}"
  namespace           = "${var.secondary_namespace}"
  public_key          = "${var.public_key}"
  demo_username       = "${var.demo_username}"
  demo_password       = "${var.demo_password}"
  servers             = "${var.servers}"
  nomadworkers        = "${var.nomadworkers}"
  vaultlicense        = "${var.vaultlicense}"
  consullicense       = "${var.consullicense}"
  enterprise          = "${var.enterprise}"
  consul_url          = "${var.consul_url}"
  consul_ent_url      = "${var.consul_ent_url}"
  packer_url          = "${var.packer_url}"
  sentinel_url        = "${var.sentinel_url}"
  consul_template_url = "${var.consul_template_url}"
  envconsul_url       = "${var.envconsul_url}"
  fabio_url           = "${var.fabio_url}"
  hashiui_url         = "${var.hashiui_url}"
  nomad_url           = "${var.nomad_url}"
  nomad_ent_url       = "${var.nomad_ent_url}"
  terraform_url       = "${var.terraform_url}"
  vault_url           = "${var.vault_url}"
  vault_ent_url       = "${var.vault_ent_url}"
  created-by          = "${var.created-by}"
  sleep-at-night      = "${var.sleep-at-night}"
  TTL                 = "${var.TTL}"
  vpc_cidr_block      = "${var.vpc_cidr_block}"
  cidr_blocks         = "${var.cidr_blocks}"
  instance_type_server= "${var.instance_type_server}"
  instance_type_worker= "${var.instance_type_worker}"
  ca_key_algorithm   = "${tls_private_key.root.algorithm}"
  ca_private_key_pem = "${tls_private_key.root.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.root.cert_pem}"
}
*/

# Root private key
resource "tls_private_key" "root" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

# Root certificate
resource "tls_self_signed_cert" "root" {
  key_algorithm   = "${tls_private_key.root.algorithm}"
  private_key_pem = "${tls_private_key.root.private_key_pem}"

  subject {
    common_name  = "service.consul"
    organization = "HashiCorp Consul Connect Demo"
  }

  validity_period_hours = 720 # 30 days

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]

  is_ca_certificate = true
}

