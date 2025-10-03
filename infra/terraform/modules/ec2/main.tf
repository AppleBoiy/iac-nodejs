locals {
  # Choose one of the default subnets in the default VPC
  subnet_id = data.aws_subnets.default.ids[0]
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = [
      "ubuntu/images/*/ubuntu-noble-24.04-amd64-server-*",
      "ubuntu/images/*/ubuntu-jammy-22.04-amd64-server-*",
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Try to find an existing SG with the expected name in the default VPC.
# Plural data sources return zero or more results without error in AWS provider v4+.
data "aws_security_groups" "existing" {
  filter {
    name   = "group-name"
    values = ["${var.key_name}-sg-ssh"]
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Create key pair only if explicitly requested; otherwise assume it already exists by name.
resource "aws_key_pair" "this" {
  count      = var.create_key_pair ? 1 : 0
  key_name   = var.key_name
  public_key = file(pathexpand(var.public_key_path))
  tags       = var.tags
}

# Create the security group only when one with the intended name does not already exist.
resource "aws_security_group" "ssh" {
  count       = length(data.aws_security_groups.existing.ids) == 0 ? 1 : 0
  name        = "${var.key_name}-sg-ssh"
  description = "Allow SSH from allowed_ssh_cidr and HTTP from anywhere"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

locals {
  # Prefer an existing SG if found; otherwise use the one created by this module.
  sg_id = try(data.aws_security_groups.existing.ids[0], aws_security_group.ssh[0].id)

  # Prefer the created key pair when requested; otherwise use the provided key name.
  key_name_to_use = try(aws_key_pair.this[0].key_name, var.key_name)
}

resource "aws_instance" "vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = local.key_name_to_use
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [local.sg_id]
  associate_public_ip_address = true

  tags = merge(var.tags, { Name = "${var.key_name}-vm" })
}
