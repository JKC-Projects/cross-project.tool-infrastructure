locals {
  github_repos_needing_aws = [
    "JKC-Projects/smalldomains.domain-manager",
    "JKC-Projects/smalldomains.web-app"
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

resource "aws_iam_role_policy_attachment" "ssm_read_write" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ssm_read_write.arn
}

resource "aws_iam_role_policy_attachment" "s3_sync" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.s3_sync.arn
}

resource "aws_iam_role_policy_attachment" "invalidate_cloudfront_cache" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.invalidate_cloudfront_cache.arn
}

resource "aws_iam_policy" "ecr_push" {
  name        = "PushDockerImageToECR"
  description = "Allows for the Pushing of Docker Images to any ECR repo"
  policy      = data.aws_iam_policy_document.ecr_push.json
}

resource "aws_iam_policy" "ssm_read_write" {
  name        = "ReadWriteAnySSMParameter"
  description = "Allows for the retrieval and writing of any SSM Parameter"
  policy      = data.aws_iam_policy_document.ssm_read_write.json
}

resource "aws_iam_policy" "s3_sync" {
  name        = "ReadWriteAnyS3Sync"
  description = "Allows for the Sync action of any S3 Bucket"
  policy      = data.aws_iam_policy_document.s3_sync.json
}

resource "aws_iam_policy" "invalidate_cloudfront_cache" {
  name        = "InvalidateCloudFrontCache"
  description = "Allows GitHub Actions to Invalidate Any CloudFront Cache"
  policy      = data.aws_iam_policy_document.invalidate_cloudfront_cache.json
}


data "aws_iam_policy_document" "ecr_push" {
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:BatchCheckLayerAvailability"
    ]
    resources = ["*"]
  }

  statement {
    actions   = ["ecr:PutImage"]
    resources = ["arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/*"]
  }
}

data "aws_iam_policy_document" "ssm_read_write" {
  statement {
    actions   = ["ssm:PutParameter", "ssm:GetParameter", "ssm:GetParameters", "ssm:AddTagsToResource"]
    resources = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:parameter/*"]
  }
}

data "aws_iam_policy_document" "invalidate_cloudfront_cache" {
  statement {
    actions   = ["cloudfront:CreateInvalidation"]
    resources = ["*"]
  }
}


data "aws_iam_policy_document" "s3_sync" {
  statement {
    actions = ["s3:DeleteObject", "s3:GetBucketLocation", "s3:GetObject", "s3:ListBucket", "s3:PutObject"]
    resources = [
      "arn:aws:s3:::*",
      "arn:aws:s3:::*/*"
    ]
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