resource "aws_alb" "nomad" {
  name = "${var.namespace}-nomad"

  security_groups = ["${aws_security_group.demostack.id}"]
  subnets         = ["${aws_subnet.demostack.*.id}"]

  tags {
    Name           = "${var.namespace}-nomad"
    owner          = "${var.owner}"
    created-by     = "${var.created-by}"
    sleep-at-night = "${var.sleep-at-night}"
    TTL            = "${var.TTL}"
  }
}

resource "aws_alb_target_group" "nomad" {
  name = "${var.namespace}-nomad"

  port     = "4646"
  vpc_id   = "${aws_vpc.demostack.id}"
  protocol = "HTTPS"

  health_check {
    interval          = "5"
    timeout           = "2"
    path              = "/v1/agent/health"
    port              = "4646"
    protocol          = "HTTPS"
    matcher           = "200,429"
    healthy_threshold = 2
  }
}

resource "aws_alb_listener" "nomad" {
  load_balancer_arn = "${aws_alb.nomad.arn}"

  port     = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.nomad.arn}"
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "nomad" {
  count            = "${var.servers}"
  target_group_arn = "${aws_alb_target_group.nomad.arn}"
  target_id        = "${element(aws_instance.server.*.id, count.index)}"
  port             = "4646"
}
