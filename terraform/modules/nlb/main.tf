# NLB:
resource "aws_lb" "nlb" {
  name               = "${var.name_prefix}-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = var.subnet_ids
  tags = {
    Name        = "${var.name_prefix}-nlb"
    Environment = var.environment
  }
}

# Target Groups:
resource "aws_lb_target_group" "controlplane_tg" {
  port        = 8080
  protocol    = "TCP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    port                = 8080
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name        = "${var.name_prefix}-controlplane-tg"
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "wireguard_tg" {

  port        = 41641
  protocol    = "UDP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    protocol            = "TCP"
    port                = 8080
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = {
    Name        = "${var.name_prefix}-wireguard-tg"
    Environment = var.environment
  }
}

# Listeners:
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 443
  protocol          = "TLS"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.controlplane_tg.arn
  }
}

resource "aws_lb_listener" "wireguard" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 41641
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.wireguard_tg.arn
  }
}
