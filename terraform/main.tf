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
  depends_on          = [module.network, module.nlb, module.ecr]
  domain_name         = var.domain_name
}


data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}


# Trust policy + IAM role for GitHub Actions to assume
data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:ei-sei/headscale-ecs:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "${var.name_prefix}-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

# Permissions policy for GitHub Actions to deploy to ECS
data "aws_iam_policy_document" "github_actions_deploy_permissions" {
  statement {
    sid       = "ECRAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid = "ECRPush"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = [module.ecr.ecr_repository_arn]
  }

  statement {
    sid = "ECSDeploy"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
    ]
    resources = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.name_prefix}-cluster/${var.name_prefix}-service"]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "${var.name_prefix}-github-actions-deploy-policy"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_deploy_permissions.json
}

data "aws_caller_identity" "current" {}
