echo "--> Configuring EBS mounts"
echo "--> Mysql"
sudo tee  /etc/nomad.d/mysql_ebs_volume.hcl > /dev/null <<EOF
# volume registration
type = "csi"
id = "mysql"
name = "mysql"
external_id = "${aws_ebs_volume_mysql_id}"
access_mode = "single-node-writer"
attachment_mode = "file-system"
plugin_id = "aws-ebs0"
EOF

echo "--> Mongodb"
sudo tee  /etc/nomad.d/mongodb_ebs_volume.hcl > /dev/null <<EOF
# volume registration
type = "csi"
id = "mongodb"
name = "mongodb"
external_id = "${aws_ebs_volume_mongodb_id}"
access_mode = "single-node-writer"
attachment_mode = "file-system"
plugin_id = "aws-ebs0"
EOF

 nomad volume register /etc/nomad.d/mongodb_ebs_volume.hcl

echo "--> Prometheus"
sudo tee  /etc/nomad.d/prometheus_ebs_volume.hcl > /dev/null <<EOF
# volume registration
type = "csi"
id = "prometheus"
name = "prometheus"
external_id = "${aws_ebs_volume_prometheus_id}"
access_mode = "single-node-writer"
attachment_mode = "file-system"
plugin_id = "aws-ebs0"
EOF

echo "--> Shared"
sudo tee  /etc/nomad.d/shared_ebs_volume.hcl > /dev/null <<EOF
# volume registration
type = "csi"
id = "shared"
name = "shared"
external_id = "${aws_ebs_volume_shared_id}"
access_mode = "single-node-writer"
attachment_mode = "file-system"
plugin_id = "aws-ebs0"
EOF

echo "==> Configuring EBS mounts is Done!"