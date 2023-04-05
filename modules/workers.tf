
# Gzip cloud-init config
data "cloudinit_config" "workers" {
  count = var.workers

  gzip          = true
  base64_encode = true

    #base
  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/shared/base.sh",{
    region     = var.region
    enterprise = var.enterprise
    node_name  = "${var.namespace}-worker-${count.index}"
    me_ca      = tls_self_signed_cert.root.cert_pem
    me_cert    = element(tls_locally_signed_cert.workers.*.cert_pem, count.index)
    me_key     = element(tls_private_key.workers.*.private_key_pem, count.index)
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
    content      = templatefile("${path.module}/templates/workers/consul.sh",{
    node_name  = "${var.namespace}-worker-${count.index}"
    region = var.region
     # Consul
    consullicense = var.consullicense
    consul_gossip_key     = var.consul_gossip_key
    consul_join_tag_key   = "ConsulJoin"
    consul_join_tag_value = var.consul_join_tag_value
    consul_master_token   = var.consul_master_token
    })
  }

   #nomad
  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/workers/nomad.sh",{
    node_name  = "${var.namespace}-worker-${count.index}"
    # Nomad
    cni_plugin_url   = var.cni_plugin_url
    })
  }

      #EBS
  part {
    content_type = "text/x-shellscript"
    content      = templatefile("${path.module}/templates/workers/ebs_volumes.sh",{
    region     = var.region
    run_nomad_jobs = var.run_nomad_jobs
    # Nomad EBS Volumes
    index                        = count.index + 1
    count                        = var.workers
    dc1                          = data.aws_availability_zones.available.names[0]
    dc2                          = data.aws_availability_zones.available.names[1]
    dc3                          = data.aws_availability_zones.available.names[2]
    aws_ebs_volume_mysql_id      = aws_ebs_volume.shared.id
    aws_ebs_volume_mongodb_id    = aws_ebs_volume.mongodb.id
    aws_ebs_volume_prometheus_id = aws_ebs_volume.prometheus.id
    aws_ebs_volume_shared_id     = aws_ebs_volume.shared.id
    })
  }
#end
}

resource "aws_instance" "workers" {
  count = var.workers

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type_worker
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
   function       = "worker"
   Name            = "${var.namespace}-worker-${count.index}" ,
   }
  )


  user_data = element(data.cloudinit_config.workers.*.rendered, count.index)
}
