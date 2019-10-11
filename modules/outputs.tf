output "servers" {
  value = aws_route53_record.servers.*.fqdn
}

output "workers" {
  value = aws_route53_record.workers.*.fqdn
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
