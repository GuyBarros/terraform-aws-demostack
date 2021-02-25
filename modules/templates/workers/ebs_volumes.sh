echo "--> Configuring EBS mounts"

export NOMAD_ADDR=https://localhost:4646

echo "--> Create EBS CSI plugin job"
{
sudo tee  /etc/nomad.d/default_jobs/plugin-ebs-controller.nomad > /dev/null <<EOF
job "plugin-aws-ebs-controller" {
  datacenters = ["${dc1}","${dc2}","${dc3}"]

  group "controller" {
    task "plugin" {
      driver = "docker"

      config {
        image = "amazon/aws-ebs-csi-driver:latest"

        args = [
          "controller",
          "--endpoint=unix://csi/csi.sock",
          "--logtostderr",
          "--v=5",
        ]
      }

      csi_plugin {
        id        = "aws-ebs0"
        type      = "controller"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
EOF
} || {
    echo "--> CSI plugin job skipped"
}
echo "--> Create Nodes CSI plugin job"
{
sudo tee  /etc/nomad.d/default_jobs/plugin-ebs-nodes.nomad > /dev/null <<EOF
job "plugin-aws-ebs-nodes" {
  datacenters = ["${dc1}","${dc2}","${dc3}"]

  # you can run node plugins as service jobs as well, but this ensures
  # that all nodes in the DC have a copy.
  type = "system"

  group "nodes" {
    task "plugin" {
      driver = "docker"

      config {
        image = "amazon/aws-ebs-csi-driver:latest"

        args = [
          "node",
          "--endpoint=unix://csi/csi.sock",
          "--logtostderr",
          "--v=5",
        ]

        # node plugins must run as privileged jobs because they
        # mount disks to the host
        privileged = true
      }

      csi_plugin {
        id        = "aws-ebs0"
        type      = "node"
        mount_dir = "/csi"
      }

      resources {
        cpu    = 500
        memory = 256
      }
    }
  }
}
EOF
} || {
    echo "--> Nodes job skipped"
}
echo "--> Mysql"
{
sudo tee  /etc/nomad.d/default_jobs/mysql_ebs_volume.hcl > /dev/null <<EOF
# volume registration
type = "csi"
id = "mysql"
name = "mysql"
external_id = "${aws_ebs_volume_mysql_id}"
access_mode = "single-node-writer"
attachment_mode = "file-system"
plugin_id = "aws-ebs0"
EOF
} || {
    echo "--> Mysql failed, probably already done"
}

echo "--> Mongodb"
{
sudo tee  /etc/nomad.d/default_jobs/mongodb_ebs_volume.hcl > /dev/null <<EOF
# volume registration
type = "csi"
id = "mongodb"
name = "mongodb"
external_id = "${aws_ebs_volume_mongodb_id}"
access_mode = "single-node-writer"
attachment_mode = "file-system"
plugin_id = "aws-ebs0"
EOF


} || {
    echo "--> MongoDB failed, probably already done"
}

echo "--> Prometheus"
{
sudo tee  /etc/nomad.d/default_jobs/prometheus_ebs_volume.hcl > /dev/null <<EOF
# volume registration
type = "csi"
id = "prometheus"
name = "prometheus"
external_id = "${aws_ebs_volume_prometheus_id}"
access_mode = "single-node-writer"
attachment_mode = "file-system"
plugin_id = "aws-ebs0"
EOF
} || {
    echo "--> Prometheus failed, probably already done"
}
echo "--> Shared"
{
sudo tee  /etc/nomad.d/default_jobs/shared_ebs_volume.hcl > /dev/null <<EOF
# volume registration
type = "csi"
id = "shared"
name = "shared"
external_id = "${aws_ebs_volume_shared_id}"
access_mode = "single-node-writer"
attachment_mode = "file-system"
plugin_id = "aws-ebs0"
EOF
} || {
    echo "--> Shared failed, probably already done"
}

if [ ${index} == ${count} ]
then
echo "--> last worker, lets do this"
nomad run  /etc/nomad.d/default_jobs/plugin-ebs-controller.nomad
nomad run  /etc/nomad.d/default_jobs/plugin-ebs-nodes.nomad

sleep 5
nomad volume register /etc/nomad.d/default_jobs/mongodb_ebs_volume.hcl
else
echo "--> not the last worker, skip"
fi


echo "==> Configuring EBS mounts is Done!"