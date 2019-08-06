resource "aws_alb" "consul" {
  name = "${var.namespace}-consul"

  security_groups = [aws_security_group.demostack.id]
  subnets         = aws_subnet.demostack.*.id

  tags = {
    Name           = "${var.namespace}-consul"
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

resource "aws_alb_target_group" "consul" {
  name = "${var.namespace}-consul"

  port     = "8500"
  vpc_id   = aws_vpc.demostack.id
  protocol = "HTTP"

  health_check {
    interval          = "5"
    timeout           = "2"
    path              = "/v1/status/leader"
    port              = "8500"
    protocol          = "HTTP"
    matcher           = "200,429"
    healthy_threshold = 2
  }
}

resource "aws_alb_listener" "consul" {
  load_balancer_arn = aws_alb.consul.arn

  port     = "8500"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.consul.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "consul" {
  count            = var.servers
  target_group_arn = aws_alb_target_group.consul.arn
  target_id        = "${element(aws_instance.server.*.id, count.index)}"
  port             = "8500"
}
