resource "aws_security_group" "demostack" {
  name_prefix = var.namespace
  vpc_id      = aws_vpc.demostack.id

tags = local.common_tags
  #Allow internal communication between nodes
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = -1
  }

  ingress {
    from_port   = 2000
    to_port     = 32000
    protocol    = "tcp"
      cidr_blocks = ["10.1.0.0/18"]
  }

  ingress {
    from_port   = 2000
    to_port     = 32000
    protocol    = "udp"
      cidr_blocks = ["10.1.0.0/18"]
  }


  ingress {
    from_port   = 2000
    to_port     = 32000
    protocol    = "tcp"
      cidr_blocks = ["10.2.0.0/18"]
  }

  ingress {
    from_port   = 2000
    to_port     = 32000
    protocol    = "udp"
      cidr_blocks = ["10.2.0.0/18"]
  }

  # SSH access if host_access_ip has CIDR blocks
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
     # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
    }
  }

 # RDP access if host_access_ip has CIDR blocks
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
    }
  }


  #HTTP
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
  }
  }

  #Demostack LDAP
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
  }
  }


  #Demostack HTTPS
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
  }
  }

#Grafana
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
    from_port   = 1521
    to_port     = 1521
    protocol    = "tcp"
    # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
  }
  }

  #Grafana
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
  }
  }

  #Demostack Postgres + pgadmin
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
    from_port   = 5000
    to_port     = 5500
    protocol    = "tcp"
    # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = flatten([ingress.value,data.tfe_ip_ranges.addresses.api])
  }
  }

  #Consul and Vault and Boundary ports
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
    from_port   = 8000
    to_port     = 9300
    protocol    = "tcp"
    # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = flatten([ingress.value,data.tfe_ip_ranges.addresses.api])
  }
  }

  #Fabio Ports
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
    from_port   = 9998
    to_port     = 9999
    protocol    = "tcp"
    # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = flatten([ingress.value,data.tfe_ip_ranges.addresses.api])
  }
  }

  #Nomad
  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
    from_port   = 3000
    to_port     = 4999
    protocol    = "tcp"
    # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = flatten([ingress.value,data.tfe_ip_ranges.addresses.api])
  }
  }

  #More nomad ports & Boundary

  dynamic "ingress" {
    for_each = var.host_access_ip
    content {
     from_port   = 20000
    to_port     = 65535
    protocol    = "tcp"
    # cidr_blocks = [ingress.value]
     cidr_blocks = ["0.0.0.0/0"]
    # cidr_blocks = flatten([ingress.value,data.tfe_ip_ranges.addresses.api])
  }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}
