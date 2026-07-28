output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [for subnet in aws_subnet.public : subnet.id]
}

output "private_app_subnet_ids" {
  description = "IDs of private app subnets"
  value       = [for subnet in aws_subnet.private_app : subnet.id]
}

output "private_db_subnet_ids" {
  description = "IDs of private database subnets"
  value       = [for subnet in aws_subnet.private_db : subnet.id]
}

output "nat_gateway_ips" {
  description = "Elastic IP addresses of NAT Gateways"
  value       = [for eip in aws_eip.nat : eip.public_ip]
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}
