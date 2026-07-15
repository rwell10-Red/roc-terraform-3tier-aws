# =============================================================================
# EC2 Instance Connect Endpoint
# =============================================================================

resource "aws_ec2_instance_connect_endpoint" "main" {
  subnet_id          = aws_subnet.private_app.id
  security_group_ids = [aws_security_group.eice.id]
  preserve_client_ip = false

  tags = {
    Name = "${local.name_prefix}-eice-${local.suffix}"
  }

  depends_on = [
    aws_subnet.private_app,
    aws_security_group.eice
  ]
}
