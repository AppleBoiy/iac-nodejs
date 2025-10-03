# Root configuration now consumes a reusable EC2 module for better structure and maintainability.
module "ec2" {
  source = "./modules/ec2"

  instance_type     = var.instance_type
  key_name          = var.key_name
  public_key_path   = var.public_key_path
  allowed_ssh_cidr  = var.allowed_ssh_cidr
  tags              = var.tags
}
