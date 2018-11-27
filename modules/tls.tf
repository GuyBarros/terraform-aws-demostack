# Root private key
resource "tls_private_key" "root" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

# Root certificate
resource "tls_self_signed_cert" "root" {
  key_algorithm   = "${tls_private_key.root.algorithm}"
  private_key_pem = "${tls_private_key.root.private_key_pem}"

  subject {
    common_name  = "service.consul"
    organization = "HashiCorp Consul Connect Demo"
  }

  validity_period_hours = 720 # 30 days

  allowed_uses = [
    "cert_signing",
    "crl_signing",
  ]

  is_ca_certificate = true
}

# Server private key
resource "tls_private_key" "server" {
  count       = "${var.servers}"
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

# Server signing request
resource "tls_cert_request" "server" {
  count           = "${var.servers}"
  key_algorithm   = "${element(tls_private_key.server.*.algorithm, count.index)}"
  private_key_pem = "${element(tls_private_key.server.*.private_key_pem, count.index)}"

  subject {
    common_name  = "${var.namespace}-server-${count.index}.node.consul"
    organization = "HashiCorp Consul Connect Demo"
  }

  dns_names = [
    # Consul
    "${var.namespace}-server-${count.index}.node.consul",

    "consul.service.consul",
    "server.dc1.consul",

    # Nomad
    "nomad.service.consul",

    "client.global.nomad",
    "server.global.nomad",

    # Vault
    "${var.namespace}-server-${count.index}.node.consul",

    "vault.service.consul",
    "active.vault.service.consul",
    "standby.vault.service.consul",

    # Common
    "localhost",
  ]

  /*
  ip_addresses = [
    "127.0.0.1",
  ]
  */
}

# Server certificate
resource "tls_locally_signed_cert" "server" {
  count              = "${var.servers}"
  cert_request_pem   = "${element(tls_cert_request.server.*.cert_request_pem, count.index)}"
  ca_key_algorithm   = "${tls_private_key.root.algorithm}"
  ca_private_key_pem = "${tls_private_key.root.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.root.cert_pem}"

  validity_period_hours = 720 # 30 days

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_agreement",
    "key_encipherment",
    "server_auth",
  ]
}

# Vault initial root token
resource "random_id" "vault-root-token" {
  byte_length = 8
  prefix      = "${var.namespace}-"
}

# Client private key

resource "tls_private_key" "workers" {
  count       = "${var.nomadworkers}"
  algorithm   = "ECDSA"
  ecdsa_curve = "P521"
}

# Client signing request
resource "tls_cert_request" "workers" {
  count           = "${var.nomadworkers}"
  key_algorithm   = "${element(tls_private_key.workers.*.algorithm, count.index)}"
  private_key_pem = "${element(tls_private_key.workers.*.private_key_pem, count.index)}"

  subject {
    common_name  = "${element(aws_iam_user.workers.*.name, count.index)}.node.consul"
    organization = "HashiCorp Consul Connect Demo"
  }

  dns_names = [
    # Consul
    "${element(aws_iam_user.workers.*.name, count.index)}.node.consul",

    # Nomad
    "nomad.service.consul",

    "client.global.nomad",

    # Common
    "localhost",
  ]

  /*
  ip_addresses = [
    "127.0.0.1",
  ]
  */
}

# Client certificate

resource "tls_locally_signed_cert" "workers" {
  count              = "${var.nomadworkers}"
  cert_request_pem   = "${element(tls_cert_request.workers.*.cert_request_pem, count.index)}"
  ca_key_algorithm   = "${tls_private_key.root.algorithm}"
  ca_private_key_pem = "${tls_private_key.root.private_key_pem}"
  ca_cert_pem        = "${tls_self_signed_cert.root.cert_pem}"

  validity_period_hours = 720 # 30 days

  allowed_uses = [
    "client_auth",
    "digital_signature",
    "key_agreement",
    "key_encipherment",
    "server_auth",
  ]
}

# Consul gossip encryption key
resource "random_id" "consul_gossip_key" {
  byte_length = 16
}

# Consul master token
resource "random_id" "consul_master_token" {
  byte_length = 16
}

# Consul join key
resource "random_id" "consul_join_tag_value" {
  byte_length = 16
}

# Nomad gossip encryption key
resource "random_id" "nomad_gossip_key" {
  byte_length = 16
}
