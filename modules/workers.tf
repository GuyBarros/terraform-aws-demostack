
resource "aws_s3_object" "worker_base" {
  count   = var.workers
  bucket  = aws_s3_bucket.bootstrap_scripts.id
  key     = "worker-${count.index}/01_base.sh"
  content = templatefile("${path.module}/templates/shared/base.sh", {
    region      = var.region
    enterprise  = var.enterprise
    node_name   = "${var.namespace}-worker-${count.index}"
    me_ca       = tls_self_signed_cert.root.cert_pem
    me_cert     = element(tls_locally_signed_cert.workers.*.cert_pem, count.index)
    me_key      = element(tls_private_key.workers.*.private_key_pem, count.index)
    vault0_cert = tls_locally_signed_cert.workers.0.cert_pem
    vault0_key  = tls_private_key.workers.0.private_key_pem
    public_key  = var.public_key
  })
}

resource "aws_s3_object" "worker_docker" {
  count   = var.workers
  bucket  = aws_s3_bucket.bootstrap_scripts.id
  key     = "worker-${count.index}/02_docker.sh"
  content = file("${path.module}/templates/shared/docker.sh")
}

resource "aws_s3_object" "worker_consul" {
  count   = var.workers
  bucket  = aws_s3_bucket.bootstrap_scripts.id
  key     = "worker-${count.index}/03_consul.sh"
  content = templatefile("${path.module}/templates/workers/consul.sh", {
    node_name             = "${var.namespace}-worker-${count.index}"
    region                = var.region
    consullicense         = var.consullicense
    consul_gossip_key     = var.consul_gossip_key
    consul_join_tag_key   = "ConsulJoin"
    consul_join_tag_value = var.consul_join_tag_value
    consul_master_token   = var.consul_master_token
  })
}

resource "aws_s3_object" "worker_nomad" {
  count   = var.workers
  bucket  = aws_s3_bucket.bootstrap_scripts.id
  key     = "worker-${count.index}/04_nomad.sh"
  content = templatefile("${path.module}/templates/workers/nomad.sh", {
    node_name           = "${var.namespace}-worker-${count.index}"
    vault_api_addr      = "https://${aws_route53_record.vault.fqdn}:8200"
    consul_master_token = var.consul_master_token
    cni_version         = var.cni_version
    nomad_servers       = var.servers - 1
  })
}

resource "aws_s3_object" "worker_ebs" {
  count   = var.workers
  bucket  = aws_s3_bucket.bootstrap_scripts.id
  key     = "worker-${count.index}/05_ebs.sh"
  content = templatefile("${path.module}/templates/workers/ebs_volumes.sh", {
    region                       = var.region
    run_nomad_jobs               = var.run_nomad_jobs
    nomad_servers                = var.servers
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
   Purpose        = var.namespace ,
   Function       = "worker"
   Name            = "${var.namespace}-worker-${count.index}" ,
   }
  )


  user_data = templatefile("${path.module}/templates/shared/bootstrap.sh", {
    bucket  = aws_s3_bucket.bootstrap_scripts.id
    prefix  = "worker-${count.index}"
    scripts = ["01_base.sh", "02_docker.sh", "03_consul.sh", "04_nomad.sh", "05_ebs.sh"]
  })

  depends_on = [
    aws_s3_object.worker_base,
    aws_s3_object.worker_docker,
    aws_s3_object.worker_consul,
    aws_s3_object.worker_nomad,
    aws_s3_object.worker_ebs,
  ]
}
