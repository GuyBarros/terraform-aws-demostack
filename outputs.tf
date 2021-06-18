////////////////////// Main //////////////////////////

output "Consul" {
  value = [
    for consul in module.primarycluster :
    consul.consul_ui
  ]
#  module.primarycluster.consul_ui
}

output "Nomad" {
  value =  [
    for nomad in module.primarycluster :
    nomad.nomad_ui
  ]
#  module.primarycluster.nomad_ui
}

output "Vault" {
  value =  [
    for vault in module.primarycluster :
    vault.vault_ui
  ]
#  module.primarycluster.vault_ui
}

output "Fabio" {
  value = [
    for fabio in module.primarycluster :
    fabio.fabio_lb
  ]
#  module.primarycluster.fabio_lb
}

output "Traefik" {
  value =  [
    for traefik in module.primarycluster :
    traefik.traefik_lb
  ]
#  module.primarycluster.traefik_lb
}

output "Boundary" {
  value =  [
    for boundary in module.primarycluster :
    boundary.boundary_ui
  ]
  #module.primarycluster.boundary_ui
}
/**
output "Primary_k8s_eks_endpoint"{
  value = module.primarycluster.eks_endpoint
}

output "Primary_k8s_eks_ca"{
  value = module.primarycluster.eks_ca
}
**/

