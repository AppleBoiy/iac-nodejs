output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.instance_public_ip
}

output "ssh_command" {
  description = "Convenient SSH command"
  value       = "ssh -i ${var.private_key_path} ubuntu@${module.ec2.instance_public_ip}"
}
