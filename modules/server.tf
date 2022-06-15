
# Gzip cloud-init config
data "template_cloudinit_config" "servers" {
  count = var.servers

  gzip          = true
  base64_encode = true

  #base
  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/shared/base.sh",{
    region = var.region
    enterprise    = var.enterprise
    node_name     = "${var.namespace}-server-${count.index}"
    me_ca      = var.ca_cert_pem
    me_cert    = element(tls_locally_signed_cert.server.*.cert_pem, count.index)
    me_key     = element(tls_private_key.server.*.private_key_pem, count.index)
    public_key = var.public_key
    })
   }

  #docker
  part {
    content_type = "text/x-shellscript"
    content      = file("${path.module}/templates/shared/docker.sh")
   }

  #consul
  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/server/consul.sh",{
    region = var.region
    node_name     = "${var.namespace}-server-${count.index}"
    # Consul
    consullicense = var.consullicense
    primary_datacenter    = var.primary_datacenter
    consul_gossip_key     = var.consul_gossip_key
    consul_join_tag_key   = "ConsulJoin"
    consul_join_tag_value = var.consul_join_tag_value
    consul_master_token   = var.consul_master_token
    consul_servers        = var.servers
    })
   }

  #vault
  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/server/vault.sh",{
    region = var.region
    enterprise    = var.enterprise
    node_name     = "${var.namespace}-server-${count.index}"
    kmskey        = aws_kms_key.demostackVaultKeys.id
    # Consul
    consul_master_token   = var.consul_master_token
    # Vault
    namespace     = var.namespace
    vault_root_token = random_id.vault-root-token.hex
    vault_servers    = var.servers
    vault_api_addr = "https://${aws_route53_record.vault.fqdn}:8200"
    })
   }

 #nomad
  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/server/nomad.sh",{
    node_name     = "${var.namespace}-server-${count.index}"
    # Nomad
    nomad_gossip_key = var.nomad_gossip_key
    nomad_servers    = var.servers
    cni_plugin_url   = var.cni_plugin_url
    nomadlicense     = var.nomadlicense
    })
   }
 #end
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
   ConsulJoin     = "${var.consul_join_tag_value}" ,
   Purpose        = "demostack" ,
   function       = "server" ,
   Name            = "${var.namespace}-server-${count.index}" ,
   }
  )

  user_data = element(data.template_cloudinit_config.servers.*.rendered, count.index)
}
