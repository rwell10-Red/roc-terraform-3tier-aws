# =============================================================================
# Application Load Balancer
# =============================================================================

# -----------------------------------------------------------------------------
# ALB
# -----------------------------------------------------------------------------

resource "aws_lb" "frontend" {
  name                       = "${local.short_prefix}-alb-${local.suffix}"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.frontend.id]
  subnets                    = [aws_subnet.public.id, aws_subnet.public_2.id]
  drop_invalid_header_fields = true
  enable_deletion_protection = true

  tags = {
    Name = "${local.name_prefix}-alb-${local.suffix}"
  }
}

# -----------------------------------------------------------------------------
# Target Group
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "frontend" {
  name     = "${local.short_prefix}-fe-tg-${local.suffix}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${local.name_prefix}-fe-tg-${local.suffix}"
  }
}

# -----------------------------------------------------------------------------
# HTTP Listener (port 80)
# -----------------------------------------------------------------------------

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }
}

# -----------------------------------------------------------------------------
# Backend Target Group
# -----------------------------------------------------------------------------

resource "aws_lb_target_group" "backend" {
  name     = "${local.short_prefix}-be-tg-${local.suffix}"
  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/api/ping"
    protocol            = "HTTP"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name = "${local.name_prefix}-be-tg-${local.suffix}"
  }
}

# -----------------------------------------------------------------------------
# Path-Based Routing: /api/* → Backend
# -----------------------------------------------------------------------------

resource "aws_lb_listener_rule" "api_to_backend" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

# -----------------------------------------------------------------------------
# HTTPS Listener (port 443) — requires ACM certificate
# Uncomment when you have a domain + certificate configured
# -----------------------------------------------------------------------------

# resource "aws_lb_listener" "https" {
#   load_balancer_arn = aws_lb.frontend.arn
#   port              = 443
#   protocol          = "HTTPS"
#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = var.acm_certificate_arn
#
#   default_action {
#     type             = "forward"
#     target_group_arn = aws_lb_target_group.frontend.arn
#   }
# }
