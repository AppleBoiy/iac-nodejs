variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name for the AWS key pair"
  type        = string
}

variable "public_key_path" {
  description = "Path to your SSH public key file (e.g., ~/.ssh/id_rsa.pub)"
  type        = string
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH to the instance"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
