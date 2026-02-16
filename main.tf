module "vpc" {
  source = "./modules/vpc"
  vpc_cidr = var.vpc_cidr
  azs      = var.azs
}

module "security-group" {
  source = "./modules/security-group"
  vpc_id = module.vpc.vpc_id
}

module "alb" {
  source = "./modules/alb"
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  sg_alb         = module.security-group.sg_alb
  certificate_arn = var.certificate_arn
}

module "asg" {
  source           = "./modules/asg"
  private_subnets  = module.vpc.private_subnets
  sg_ec2           = module.security-group.sg_ec2
  target_group_arn = module.alb.target_group_arn
  ami_id           = var.ami_id
  instance_type    = var.instance_type
}

module "s3" {
  source = "./modules/s3"
}


