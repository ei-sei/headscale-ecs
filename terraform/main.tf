module "network" {
  source             = "./modules/vpc"
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  environment        = var.environment
  name_prefix        = var.name_prefix
}

module "ecr" {
  source      = "./modules/ecr"
  environment = var.environment
  name_prefix = var.name_prefix
}
