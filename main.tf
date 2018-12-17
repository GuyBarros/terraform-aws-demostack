# Using a single workspace:

terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "emea-se-playground"
    token = "TFE_API_TOKEN"
    workspaces {
      name = "Guy-TFE-Remote-Backend"
    }
  }
}


provider "aws" {
  version = ">= 1.20.0"
  region  = "${var.primary_region}"
}



module "primarycluster" {
  source              = "./modules"
  #source              = "github.com/GuyBarros/terraform-aws-demostack"
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
//  ca_key_algorithm   = "${var.ca_key_algorithm}"
//  ca_private_key_pem = "${var.ca_private_key_pem}"
//  ca_cert_pem        = "${var.ca_cert_pem}"
ca_key_algorithm   = "${module.rootcertificate.ca_key_algorithm}"
  ca_private_key_pem = "${module.rootcertificate.ca_private_key_pem}"
  ca_cert_pem        = "${module.rootcertificate.ca_cert_pem}"
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
//  ca_key_algorithm   = "${var.ca_key_algorithm}"
//  ca_private_key_pem = "${var.ca_private_key_pem}"
//  ca_cert_pem        = "${var.ca_cert_pem}"
ca_key_algorithm   = "${module.rootcertificate.ca_key_algorithm}"
  ca_private_key_pem = "${module.rootcertificate.ca_private_key_pem}"
  ca_cert_pem        = "${module.rootcertificate.ca_cert_pem}"
}
*/

module "rootcertificate" {
  source              = "github.com/GuyBarros/terraform-tls-certificate"
  version = "0.0.1"
  algorithm = "ECDSA"
  ecdsa_curve = "P521"
  common_name   = "service.consul"
  organization = "service.consul"
  validity_period_hours = 720
  is_ca_certificate = true
}

