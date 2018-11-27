
provider "consul" {
 address = "http://${element(aws_instance.angularjs.*.public_ip, 0)}:8500"
 }

# Access a key in Consul
resource "consul_keys" "app" {
  key {
    path    = "service/app/launch_ami"
    value = "ami-1234"
  }
}

resource "consul_intention" "angularjs" {
  source_name      = "angularjs"
  destination_name = "nodejs"
  action           = "allow"
}

resource "consul_intention" "nodejs" {
  source_name      = "nodejs"
  destination_name = "mongodb"
  action           = "allow"
}
