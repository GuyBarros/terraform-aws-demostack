// Primary
output "nomad_workers_server" {
  value = ["${module.primarycluster.nomad_workers_server}"]
}

output "nomad_workers_consul_ui" {
  value = ["${module.primarycluster.nomad_workers_consul_ui}"]
}

output "nomad_workers_ui" {
  value = ["${module.primarycluster.nomad_workers_ui}"]
}

output "primary_consul_servers" {
  value = "${module.primarycluster.consul_servers}"
}

output "primary_vault_ui" {
  value = "${module.primarycluster.vault_ui}"
}

output "primary_vpc_id" {
  value = "${module.primarycluster.vpc_id}"
}

output "fabio_lb" {
  value = "${module.primarycluster.fabio_lb}"
}

output "vault_lb" {
  value = "${module.primarycluster.vault_lb}"
}

output "vault_ui" {
  value = "${module.primarycluster.vault_ui}"
}

/*

// Secondary
output "nomad_workers_server" {
  value = ["${module.secondarycluster.nomad_workers_server}"]
}

output "nomad_workers_consul_ui" {
  value = ["${module.secondarycluster.nomad_workers_consul_ui}"]
}

output "nomad_workers_ui" {
  value = ["${module.secondarycluster.nomad_workers_ui}"]
}

output "primary_consul_servers" {
  value = "${module.secondarycluster.consul_servers}"
}

output "primary_vault_ui" {
  value = "${module.secondarycluster.vault_ui}"
}

output "primary_vpc_id" {
  value = "${module.secondarycluster.vpc_id}"
}

output "fabio_lb" {
  value = "${module.secondarycluster.fabio_lb}"
}

output "vault_lb" {
  value = "${module.secondarycluster.vault_lb}"
}

output "vault_ui" {
  value = "${module.secondarycluster.vault_ui}"
}

*/

