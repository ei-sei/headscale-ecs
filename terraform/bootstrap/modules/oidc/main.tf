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
      values = [
        "repo:ei-sei/headscale-ecs:ref:refs/heads/main",
        "repo:ei-sei/headscale-ecs:pull_request",
      ]
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
    resources = [var.ecr_repository_arn]
  }

  statement {
    sid = "ECSDeploy"
    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices",
    ]
    resources = ["arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:service/${var.name_prefix}-cluster/${var.name_prefix}-service"]
  }

  statement {
    sid = "TerraformStateBucket"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      var.state_bucket_arn,
      "${var.state_bucket_arn}/*",
    ]
  }
  statement {
    sid = "ECRManage"
    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:DescribeRepositories",
      "ecr:SetRepositoryPolicy",
      "ecr:PutLifecyclePolicy",
      "ecr:TagResource",
      "ecr:ListTagsForResource",
    ]
    resources = [var.ecr_repository_arn]
  }

  # EC2/VPC, ELB, ACM, and CloudWatch Logs don't support fine-grained
  # resource-level permissions for most create/manage actions, so these
  # are scoped to the service level instead.
  statement {
    sid       = "TerraformEC2"
    actions   = ["ec2:*"]
    resources = ["*"]
  }

  statement {
    sid       = "TerraformELB"
    actions   = ["elasticloadbalancing:*"]
    resources = ["*"]
  }

  statement {
    sid       = "TerraformACM"
    actions   = ["acm:*"]
    resources = ["*"]
  }

  statement {
    sid       = "TerraformLogs"
    actions   = ["logs:*"]
    resources = ["*"]
  }

  statement {
    sid = "TerraformECSManage"
    actions = [
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:DescribeClusters",
      "ecs:CreateService",
      "ecs:DeleteService",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:ListTaskDefinitions",
      "ecs:TagResource",
    ]
    resources = ["*"]
  }

  # IAM is scoped to roles this project creates, never iam:* on *.
  statement {
    sid = "TerraformIAMRoleManagement"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:PassRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:TagRole",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.name_prefix}-*"]
  }

}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "${var.name_prefix}-github-actions-deploy-policy"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_deploy_permissions.json
}

data "aws_caller_identity" "current" {}


