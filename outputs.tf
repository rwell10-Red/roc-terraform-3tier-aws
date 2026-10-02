output "alb_dns_name" {
  description = "DNS name of the internet-facing Application Load Balancer"
  value       = aws_lb.frontend.dns_name
}

output "rds_endpoint" {
  description = "Connection endpoint for the RDS MySQL instance"
  value       = aws_db_instance.main.endpoint
}

output "vpc_id" {
  description = "ID of the provisioned VPC"
  value       = aws_vpc.main.id
}

output "frontend_asg_name" {
  description = "Name of the front-end Auto Scaling Group"
  value       = aws_autoscaling_group.frontend.name
}

output "backend_asg_name" {
  description = "Name of the back-end Auto Scaling Group"
  value       = aws_autoscaling_group.backend.name
}
