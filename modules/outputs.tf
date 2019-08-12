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
  value = "http://${aws_instance.workers.0.public_dns}:3000"
}

output "fabio_lb" {
  value = "http://${aws_alb.fabio.dns_name}:9999"
}

output "vault_ui" {
  value = "http://${aws_alb.vault.dns_name}:8200"
}

output "nomad_ui" {
  value = "http://${aws_alb.nomad.dns_name}:4646"
}

output "consul_ui" {
  value = "http://${aws_alb.consul.dns_name}:8500"
}
