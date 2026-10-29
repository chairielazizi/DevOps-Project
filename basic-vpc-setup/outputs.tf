output "vpc_id" {
  value = aws_vpc.main.id
  description = "The ID of provisioned VPC"
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
  description = "The IDs of provisioned public subnets"
}

output "private_subnet_ids" {
  value = aws_subnet.application[*].id
  description = "The IDs of provisioned private subnets"
}

output "application_subnets_ids" {
  value = aws_subnet.application[*].id
  description = "The IDs of provisioned application subnets"
}

output "database_subnets_ids" {
  value = aws_subnet.database[*].id
  description = "The IDs of provisioned database subnets"
}

output "nat_gatway_public_ip" {
  value = aws_eip.nat.public_ip
  description = "The public elastic IP assigned to the NAT gateway"
}