output "ssh_for_servers" {
  value = "${formatlist("ssh -i /Users/guy/.ssh/id_rsa ubuntu@%s", aws_instance.server.*.public_dns,)}"
}

output "ssh_for_workers" {
  value = "${formatlist("ssh demo@%s", aws_instance.workers.*.public_dns,)}"
}

output "nomad_workers_consul_ui" {
  value = "${formatlist("http://%s:8500/", aws_instance.workers.*.public_dns,)}"
}

output "nomad_workers_ui" {
  value = "${formatlist("http://%s:3000/", aws_instance.workers.*.public_dns)}"
}

output "fabio_lb" {
  value = "${aws_alb.fabio.dns_name}"
}

output "vault_root_token" {
  value = "${random_id.vault-root-token.hex}"
}

output "vault_lb" {
  value = "${aws_alb.vault.dns_name}"
}

output "vault_ui" {
  value = "http://${aws_alb.vault.dns_name}"
}

output "nomad_ui" {
  value = "http://${aws_alb.nomad.dns_name}"
}

output "consul_ui" {
  value = "http://${aws_alb.consul.dns_name}"
}

/*
output "zStartscript" {
  value = <<README
  this is a test:
rs.initiate({
   _id : rs0,
  README
}

output "zmembers: " {
  value = "${formatlist("{ host : \"%s:27017\" }",aws_instance.workers.*.private_ip,)}"
}

output "zzendscript" {
  value = <<README
})
  README
}
*/

