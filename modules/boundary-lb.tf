resource "aws_alb" "boundary" {
  name = "${var.namespace}-boundary"

  security_groups = [aws_security_group.demostack.id]
  subnets         = aws_subnet.demostack.*.id

  tags = {
    Name           = "${var.namespace}-boundary"
    owner          = var.owner
    created-by     = var.created-by
    sleep-at-night = var.sleep-at-night
    TTL            = var.TTL
  }
}

resource "aws_alb_target_group" "boundary" {
  name     = "${var.namespace}-boundary"
  port     = "9202"
  vpc_id   = aws_vpc.demostack.id
  protocol = "HTTP"

}

resource "aws_alb_target_group" "boundary-ui" {
  name     = "${var.namespace}-boundary-ui"
  port     = "9200"
  vpc_id   = aws_vpc.demostack.id
  protocol = "HTTP"

}

resource "aws_alb_listener" "boundary" {
  load_balancer_arn = aws_alb.boundary.arn

  port     = "9202"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.boundary.arn
    type             = "forward"
  }
}

resource "aws_alb_listener" "boundary-ui" {
  load_balancer_arn = aws_alb.boundary.arn

  port     = "9200"
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.boundary-ui.arn
    type             = "forward"
  }
}

resource "aws_alb_target_group_attachment" "boundary-workers" {
  count            = var.workers
  target_group_arn = aws_alb_target_group.boundary.arn
  target_id        = element(aws_instance.workers.*.id, count.index)
  port             = "9202"
}

resource "aws_alb_target_group_attachment" "boundary-ui-workers" {
  count            = var.workers
  target_group_arn = aws_alb_target_group.boundary-ui.arn
  target_id        = element(aws_instance.workers.*.id, count.index)
  port             = "9200"
}

resource "aws_alb_target_group_attachment" "boundary-servers" {
  count            = var.servers
  target_group_arn = aws_alb_target_group.boundary.arn
  target_id        = element(aws_instance.servers.*.id, count.index)
  port             = "9202"
}

resource "aws_alb_target_group_attachment" "boundary-ui-servers" {
  count            = var.servers
  target_group_arn = aws_alb_target_group.boundary-ui.arn
  target_id        = element(aws_instance.servers.*.id, count.index)
  port             = "9200"
}
