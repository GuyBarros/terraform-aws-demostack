data "template_file" "workers" {
  count = var.workers

  template = "${join("\n", list(
    file("${path.module}/templates/shared/base.sh"),
    file("${path.module}/templates/shared/docker.sh"),
    file("${path.module}/templates/shared/run-proxy.sh"),
    file("${path.module}/templates/workers/consul.sh"),
    file("${path.module}/templates/workers/vault.sh"),
    file("${path.module}/templates/workers/nomad.sh"),
    ))}"

  vars = {
    namespace  = var.namespace
    region     = var.region
    node_name  = "${var.namespace}-worker-${count.index}"
    enterprise = var.enterprise

    #me_ca     = "${tls_self_signed_cert.root.cert_pem}"
    me_ca   = var.ca_cert_pem
    me_cert = "${element(tls_locally_signed_cert.workers.*.cert_pem, count.index)}"
    me_key  = "${element(tls_private_key.workers.*.private_key_pem, count.index)}"
    public_key = var.public_key

    # Consul
    consul_url            = var.consul_url
    consul_ent_url        = var.consul_ent_url
    consul_gossip_key     = var.consul_gossip_key
    consul_join_tag_key   = "ConsulJoin"
    consul_join_tag_value = var.consul_join_tag_value

    # Nomad
    nomad_url      =  var.nomad_url
    run_nomad_jobs = var.run_nomad_jobs

    # Vault
    vault_url        = var.vault_url
    vault_ent_url    = var.vault_ent_url
    vault_root_token = random_id.vault-root-token.hex
    vault_servers    = var.workers
  }
}

# Gzip cloud-init config
data "template_cloudinit_config" "workers" {
  count = var.workers

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = "${element(data.template_file.workers.*.rendered, count.index)}"
  }
}

resource "aws_instance" "workers" {
  count = var.workers

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_worker
  key_name      = aws_key_pair.demostack.id

  subnet_id              = "${element(aws_subnet.demostack.*.id, count.index)}"
  iam_instance_profile   = aws_iam_instance_profile.consul-join.name
  vpc_security_group_ids = [aws_security_group.demostack.id]


  root_block_device{
    volume_size           = "50"
    delete_on_termination = "true"
  }

   ebs_block_device  {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "50"
    delete_on_termination = "true"
  }

  tags = {
    Name       = "${var.namespace}-workers-${count.index}"
    owner      = var.owner
    created-by = var.created-by
  }

  user_data = "${element(data.template_cloudinit_config.workers.*.rendered, count.index)}"
}
