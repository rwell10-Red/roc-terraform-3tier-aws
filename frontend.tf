# =============================================================================
# Front-End Tier: Launch Template, Auto Scaling Group, and Scaling Policies
# =============================================================================

# -----------------------------------------------------------------------------
# Launch Template
# -----------------------------------------------------------------------------

resource "aws_launch_template" "frontend" {
  name_prefix   = "${local.name_prefix}-frontend-"
  image_id      = local.ami_id
  instance_type = var.fe_instance_type

  user_data = var.fe_user_data != "" ? base64encode(var.fe_user_data) : null

  metadata_options {
    http_tokens = "required"
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.frontend.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.frontend.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.name_prefix}-frontend-${local.suffix}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Group
# -----------------------------------------------------------------------------

resource "aws_autoscaling_group" "frontend" {
  name                = "${local.name_prefix}-frontend-asg-${local.suffix}"
  vpc_zone_identifier = [aws_subnet.public.id]

  min_size         = var.fe_min_size
  max_size         = var.fe_max_size
  desired_capacity = var.fe_desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-frontend"
    propagate_at_launch = true
  }
}

# -----------------------------------------------------------------------------
# ASG Attachment to ALB Target Group
# -----------------------------------------------------------------------------

resource "aws_autoscaling_attachment" "frontend" {
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  lb_target_group_arn    = aws_lb_target_group.frontend.arn
}

# -----------------------------------------------------------------------------
# Scaling Policy: Target Tracking (CPU Utilization)
# -----------------------------------------------------------------------------

resource "aws_autoscaling_policy" "frontend_cpu_target_tracking" {
  name                   = "${local.name_prefix}-frontend-cpu-target-tracking-${local.suffix}"
  autoscaling_group_name = aws_autoscaling_group.frontend.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = var.scale_out_threshold
    disable_scale_in = false
  }
}
