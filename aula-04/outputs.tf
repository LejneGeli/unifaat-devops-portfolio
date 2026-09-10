output "vpc_id" {
  description = "ID da VPC TechNova."
  value       = aws_vpc.technova.id
}

output "public_subnet_ids" {
  description = "IDs das duas subnets públicas."
  value       = [for key in sort(keys(aws_subnet.public)) : aws_subnet.public[key].id]
}

output "private_subnet_ids" {
  description = "IDs das duas subnets privadas."
  value       = [for key in sort(keys(aws_subnet.private)) : aws_subnet.private[key].id]
}

output "api_security_group_id" {
  value = aws_security_group.api.id
}

output "db_security_group_id" {
  value = aws_security_group.db.id
}

output "ec2_public_ip" {
  value = aws_instance.api.public_ip
}

output "api_url" {
  value = "http://${aws_instance.api.public_ip}:3000"
}

output "ssh_command" {
  value = "ssh -i ${local_sensitive_file.private_key.filename} ec2-user@${aws_instance.api.public_ip}"
}
