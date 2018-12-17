// Primary

output "primary_ssh_for_servers" {
  value = ["${module.primarycluster.ssh_for_servers}"]
}

output "primary_ssh_for_workers" {
  value = ["${module.primarycluster.ssh_for_workers}"]
}


output "primary_nomad_workers_consul_ui" {
  value = ["${module.primarycluster.nomad_workers_consul_ui}"]
}

output "primary_nomad_workers_ui" {
  value = ["${module.primarycluster.nomad_workers_ui}"]
}


output "primary_vpc_id" {
  value = "${module.primarycluster.vpc_id}"
}

output "primary_fabio_lb" {
  value = "${module.primarycluster.fabio_lb}"
}

output "primary_vault_lb" {
  value = "${module.primarycluster.vault_lb}"
}

output "primary_vault_ui" {
  value = "${module.primarycluster.vault_ui}"
}


// Secondary
/*
output "secondary_nomad_workers_server" {
  value = ["${module.secondarycluster.nomad_workers_server}"]
}

output "secondary_nomad_workers_consul_ui" {
  value = ["${module.secondarycluster.nomad_workers_consul_ui}"]
}

output "secondary_nomad_workers_ui" {
  value = ["${module.secondarycluster.nomad_workers_ui}"]
}

output "secondary_primary_consul_servers" {
  value = "${module.secondarycluster.consul_servers}"
}

output "secondary_vpc_id" {
  value = "${module.secondarycluster.vpc_id}"
}

output "secondary_fabio_lb" {
  value = "${module.secondarycluster.fabio_lb}"
}

output "secondary_vault_lb" {
  value = "${module.secondarycluster.vault_lb}"
}

output "secondary_vault_ui" {
  value = "${module.secondarycluster.vault_ui}"
}
*/



