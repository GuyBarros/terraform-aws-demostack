
resource "aws_s3_object" "server_base" {
  count   = var.servers
  bucket  = aws_s3_bucket.bootstrap_scripts.id
  key     = "server-${count.index}/01_base.sh"
  content = templatefile("${path.module}/templates/shared/base.sh", {
    region      = var.region
    enterprise  = var.enterprise
    node_name   = "${var.namespace}-server-${count.index}"
    me_ca       = tls_self_signed_cert.root.cert_pem
    me_cert     = element(tls_locally_signed_cert.server.*.cert_pem, count.index)
    me_key      = element(tls_private_key.server.*.private_key_pem, count.index)
    vault0_cert = tls_locally_signed_cert.server.0.cert_pem
    vault0_key  = tls_private_key.server.0.private_key_pem
    public_key  = var.public_key
  })
}

resource "aws_s3_object" "server_docker" {
  count   = var.servers
  bucket  = aws_s3_bucket.bootstrap_scripts.id
  key     = "server-${count.index}/02_docker.sh"
  content = file("${path.module}/templates/shared/docker.sh")
}

resource "aws_s3_object" "server_consul" {
  count   = var.servers
  bucket  = aws_s3_bucket.bootstrap_scripts.id
  key     = "server-${count.index}/03_consul.sh"
  content = templatefile("${path.module}/templates/server/consul.sh", {
    region                = var.region
    namespace             = var.namespace
    node_name             = "${var.namespace}-server-${count.index}"
    consullicense         = var.consullicense
    primary_datacenter    = var.primary_datacenter
    consul_gossip_key     = var.consul_gossip_key
    consul_join_tag_key   = "ConsulJoin"
    consul_join_tag_value = var.consul_join_tag_value
    consul_master_token   = var.consul_master_token
    consul_servers        = var.servers
  })
}

resource "aws_s3_object" "server_vault" {
  count   = var.servers
  bucket  = aws_s3_bucket.bootstrap_scripts.id
  key     = "server-${count.index}/04_vault.sh"
  content = templatefile("${path.module}/templates/server/vault.sh", {
    index                = count.index + 1
    count                = var.servers
    region               = var.region
    enterprise           = var.enterprise
    node_name            = "${var.namespace}-server-${count.index}"
    kmskey               = aws_kms_key.demostackVaultKeys.id
    consul_master_token  = var.consul_master_token
    vaultlicense         = var.vaultlicense
    namespace            = var.namespace
    vault_root_token     = random_id.vault-root-token.hex
    vault_servers        = var.servers
    vault_api_addr       = "https://${aws_route53_record.vault.fqdn}:8200"
    vault_join_tag_key   = "VaultJoin"
    vault_join_tag_value = var.consul_join_tag_value
    NOMAD_LB             = "$https://${aws_route53_record.nomad.fqdn}:4646"
  })
}

resource "aws_s3_object" "server_nomad" {
  count   = var.servers
  bucket  = aws_s3_bucket.bootstrap_scripts.id
  key     = "server-${count.index}/05_nomad.sh"
  content = templatefile("${path.module}/templates/server/nomad.sh", {
    node_name           = "${var.namespace}-server-${count.index}"
    namespace           = var.namespace
    consul_master_token = var.consul_master_token
    vault_api_addr      = "https://${aws_route53_record.vault.fqdn}:8200"
    nomad_gossip_key    = var.nomad_gossip_key
    nomad_servers       = var.servers - 1
    cni_version         = var.cni_version
    nomadlicense        = var.nomadlicense
  })
}

resource "aws_instance" "servers" {
  count = var.servers

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_server
  key_name      = aws_key_pair.demostack.id

  subnet_id              = element(aws_subnet.demostack.*.id, count.index)
  iam_instance_profile   = aws_iam_instance_profile.consul-join.name
  vpc_security_group_ids = [aws_security_group.demostack.id]
  root_block_device {
    volume_size           = "240"
    delete_on_termination = "true"
  }

  ebs_block_device {
    device_name           = "/dev/xvdd"
    volume_type           = "gp2"
    volume_size           = "240"
    delete_on_termination = "true"
  }


  tags = merge(local.common_tags ,{
   VaultJoin     = "${var.consul_join_tag_value}" ,
   ConsulJoin     = "${var.consul_join_tag_value}" ,
   Purpose        = var.namespace ,
   Function       = "server" ,
   Name            = "${var.namespace}-server-${count.index}" ,
   }
  )

  user_data = templatefile("${path.module}/templates/shared/bootstrap.sh", {
    bucket  = aws_s3_bucket.bootstrap_scripts.id
    prefix  = "server-${count.index}"
    scripts = ["01_base.sh", "02_docker.sh", "03_consul.sh", "04_vault.sh", "05_nomad.sh"]
  })

  depends_on = [
    aws_s3_object.server_base,
    aws_s3_object.server_docker,
    aws_s3_object.server_consul,
    aws_s3_object.server_vault,
    aws_s3_object.server_nomad,
  ]
}
