////////////////////// Module //////////////////////////

output "consul_master_token" {
  value     = var.consul_master_token
  sensitive = false
}

output "vault_root_token" {
  value     = random_id.vault-root-token.hex
  sensitive = false
}

# Nomad bootstrap token is generated at runtime via `nomad acl bootstrap` on server-0
# and stored in Consul KV at service/nomad/bootstrap-token — not available as a Terraform value.
output "nomad_master_token" {
  value     = "retrieve via: consul kv get service/nomad/bootstrap-token"
  sensitive = false
}
output "servers" {
  value = aws_route53_record.servers.*.fqdn
}

output "workers" {
  value = aws_route53_record.workers.*.fqdn
}

output "vpc_id" {
  value = aws_vpc.demostack.id
}

output "subnet_ids" {
  value = aws_subnet.demostack.*.id
}

output "traefik_lb" {
  value = "http://${aws_route53_record.traefik.fqdn}:8080"
}

output "fabio_lb" {
  value = "http://${aws_route53_record.fabio.fqdn}:9999"
}

output "vault_ui" {
  value = "https://${aws_route53_record.vault.fqdn}:8200"
}

output "nomad_ui" {
  value = "https://${aws_route53_record.nomad.fqdn}:4646"
}

output "consul_ui" {
  value = "https://${aws_route53_record.consul.fqdn}:8500"
}

output "boundary_ui" {
 value = "http://${aws_route53_record.boundary.fqdn}:9200"
 # value = "troubleshooting"
}


/*
output "eks_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}
output "eks_ca" {
 // value = aws_eks_cluster.eks.endpoint
  value = aws_eks_cluster.eks.certificate_authority.0.data
}
*/