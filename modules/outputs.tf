output "servers" {
  value = [aws_instance.server.*.public_dns]
}

output "workers" {
  value = [aws_instance.workers.*.public_dns]
}

output "nomad_workers_consul_ui" {
  value = "${formatlist("http://%s:8500/", aws_instance.workers.*.public_dns,)}"
}

output "nomad_workers_ui" {
  value = "${formatlist("http://%s:3000/", aws_instance.workers.*.public_dns)}"
}

output "hashi_ui" {
  value = "http://${aws_route53_record.hashiui.fqdn}:3000"
}

output "fabio_lb" {
  value = "http://${aws_route53_record.fabio.fqdn}:9999"
}

output "vault_ui" {
  value = "http://${aws_route53_record.vault.fqdn}:8200"
}

output "nomad_ui" {
  value = "http://${aws_route53_record.nomad.fqdn}:4646"
}

output "consul_ui" {
  value = "http://${aws_route53_record.consul.fqdn}:8500"
}
