# =============================================================================
# Back-End Tier: Launch Template, Auto Scaling Group, and Scaling Policies
# =============================================================================

# -----------------------------------------------------------------------------
# Launch Template
# -----------------------------------------------------------------------------

resource "aws_launch_template" "backend" {
  name_prefix   = "${local.name_prefix}-backend-"
  image_id      = local.ami_id
  instance_type = var.be_instance_type

  user_data = base64encode(templatefile("${path.module}/scripts/backend-userdata.sh", {
    DB_HOST    = aws_db_instance.main.address
    DB_PORT    = var.db_port
    DB_USER    = var.db_username
    AWS_REGION = var.region
  }))

  metadata_options {
    http_tokens = "required"
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.backend.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.backend.name
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.name_prefix}-backend-${local.suffix}"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# Auto Scaling Group
# -----------------------------------------------------------------------------

resource "aws_autoscaling_group" "backend" {
  name                = "${local.name_prefix}-backend-asg-${local.suffix}"
  vpc_zone_identifier = [aws_subnet.private_app.id]

  min_size         = var.be_min_size
  max_size         = var.be_max_size
  desired_capacity = var.be_desired_capacity

  health_check_type         = "ELB"
  health_check_grace_period = 300

  target_group_arns = [aws_lb_target_group.backend.arn]

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-backend"
    propagate_at_launch = true
  }
}

# -----------------------------------------------------------------------------
# Scaling Policy: Target Tracking (CPU Utilization)
# -----------------------------------------------------------------------------

resource "aws_autoscaling_policy" "backend_cpu_target_tracking" {
  name                   = "${local.name_prefix}-backend-cpu-target-tracking-${local.suffix}"
  autoscaling_group_name = aws_autoscaling_group.backend.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value     = var.scale_out_threshold
    disable_scale_in = false
  }
}
