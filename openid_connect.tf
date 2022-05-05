resource "aws_iam_openid_connect_provider" "oidc_for_github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938FD4D98BAB03FAADB97B34396831E3780AEA1"]
}