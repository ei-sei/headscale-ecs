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

module "acm" {
  source             = "./modules/acm"
  domain_name        = var.domain_name
  cloudflare_zone_id = var.cloudflare_zone_id
  environment        = var.environment
}

module "nlb" {
  source          = "./modules/nlb"
  environment     = var.environment
  name_prefix     = var.name_prefix
  vpc_id          = module.network.vpc_id
  certificate_arn = module.acm.certificate_arn
  subnet_ids      = module.network.public_subnet_ids
}

module "ecs" {
  source              = "./modules/ecs"
  aws_region          = var.aws_region
  environment         = var.environment
  name_prefix         = var.name_prefix
  vpc_id              = module.network.vpc_id
  ecr_repository_url  = module.ecr.ecr_repository_url
  private_subnet_id   = module.network.private_subnet_ids
  tg_controlplane_arn = module.nlb.tg_controlplane_arn
  tg_wireguard_arn    = module.nlb.tg_wireguard_arn
  depends_on = [module.network, module.nlb, module.ecr]
}
