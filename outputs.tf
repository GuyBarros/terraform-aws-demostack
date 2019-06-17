// Primary

output "Consul" {
  value = module.primarycluster.consul_ui
}

output "Nomad" {
  value = module.primarycluster.nomad_ui
}

output "Vault" {
  value = module.primarycluster.vault_ui
}

output "Fabio" {
  value = module.primarycluster.fabio_lb
}

output "Hashi_UI" {
  value = module.primarycluster.hashi_ui
}

output "ssh_Worked_Nodes" {
  value = [module.primarycluster.ssh_for_workers]
}

output "ssh_Server_nodes" {
  value = [module.primarycluster.ssh_for_servers]
}

// Secondary
/*


output "secondary_ssh_for_servers" {
  value = ["${module.secondarycluster.ssh_for_servers}"]
}

output "secondary_ssh_for_workers" {
  value = ["${module.secondarycluster.ssh_for_workers}"]
}

output "secondary_nomad_workers_consul_ui" {
  value = ["${module.secondarycluster.nomad_workers_consul_ui}"]
}

output "secondary_nomad_workers_ui" {
  value = ["${module.secondarycluster.nomad_workers_ui}"]
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
