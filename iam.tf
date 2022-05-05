locals {
  github_repos_needing_aws = [
    "JKC-Project/smalldomains.domain-manager"
  ]
}

resource "aws_iam_role" "github_actions" {
  name               = "RoleForGithubActions"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecr_push" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecr_push.arn
}

resource "aws_iam_role_policy_attachment" "ssm_read" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ssm_read.arn
}

resource "aws_iam_policy" "ecr_push" {
  name        = "PushDockerImageToECR"
  description = "Allows for the Pushing of Docker Images to any ECR repo"
  policy      = data.aws_iam_policy_document.ecr_push.json
}

resource "aws_iam_policy" "ssm_read" {
  name        = "ReadAnySSMParameter"
  description = "Allows for the retrieval of any SSM Parameter"
  policy      = data.aws_iam_policy_document.ssm_read.json
}

data "aws_iam_policy_document" "ecr_push" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    actions   = ["ecr:PutImage"]
    resources = ["arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/*"]
  }
}

data "aws_iam_policy_document" "ssm_read" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/*"]
  }
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  dynamic "statement" {
    iterator = repo_name
    for_each = local.github_repos_needing_aws

    content {
      actions = ["sts:AssumeRoleWithWebIdentity"]
      principals {
        type        = "Federated"
        identifiers = [aws_iam_openid_connect_provider.oidc_for_github.arn]
      }
      condition {
        test     = "StringEquals"
        variable = "token.actions.githubusercontent.com:sub"
        values   = ["repo:${repo_name.value}:environment:${local.long_env_names[var.environment]}"]
      }
    }
  }
}