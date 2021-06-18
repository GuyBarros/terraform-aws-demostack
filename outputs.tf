////////////////////// Main //////////////////////////

output "Primary_Consul" {
  value = module.primarycluster.consul_ui
}

output "Primary_Nomad" {
  value = module.primarycluster.nomad_ui
}

output "Primary_Vault" {
  value = module.primarycluster.vault_ui
}

output "Primary_Fabio" {
  value = module.primarycluster.fabio_lb
}

output "Primary_Traefik" {
  value = module.primarycluster.traefik_lb
}

output "Primary_Boundary" {
  value = module.primarycluster.boundary_ui
}
/**
output "Primary_k8s_eks_endpoint"{
  value = module.primarycluster.eks_endpoint
}

output "Primary_k8s_eks_ca"{
  value = module.primarycluster.eks_ca
}
**/

