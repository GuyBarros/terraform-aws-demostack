////////////////////// Main //////////////////////////

output "Consul" {
  value = [
    for consul in module.cluster :
    consul.consul_ui
  ]
}

output "Nomad" {
  value = [
    for nomad in module.cluster :
    nomad.nomad_ui
  ]
}

output "Vault" {
  value = [
    for vault in module.cluster :
    vault.vault_ui
  ]
}

output "Fabio" {
  value = [
    for fabio in module.cluster :
    fabio.fabio_lb
  ]
}

output "Traefik" {
  value = [
    for traefik in module.cluster :
    traefik.traefik_lb
  ]
}

output "Boundary" {
  value = [
    for boundary in module.cluster :
    boundary.boundary_ui
  ]
}

output "Servers" {
  value = [
    for server in module.cluster :
    server.servers
  ]
}
/**
output "Primary_k8s_eks_endpoint"{
  value = module.primarycluster.eks_endpoint
}

output "Primary_k8s_eks_ca"{
  value = module.primarycluster.eks_ca
}
**/

