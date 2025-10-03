variable "aws_region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name for the AWS key pair"
  type        = string
  default     = "demo-terraform"
}

variable "public_key_path" {
  description = "Path to your SSH public key file (e.g., ~/.ssh/id_rsa.pub)"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "private_key_path" {
  description = "Path to your SSH private key file for connecting (not uploaded to AWS)"
  type        = string
  default     = "~/.ssh/id_rsa"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to the instance. For better security, restrict to your IP, e.g., 203.0.113.4/32"
  type        = string
  default     = "0.0.0.0/0"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {
    Project   = "demo-terraform"
    ManagedBy = "terraform"
  }
}
