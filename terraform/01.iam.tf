### OpenID Provider for Github ###
resource "aws_iam_openid_connect_provider" "github_provider" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

### Assume Role Policy ###
data "aws_iam_policy_document" "github_action_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_provider.arn]
    }

    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}@${var.github_org_id}/${var.github_repo}@${var.github_repo_id}:*"]
    }
  }
}

### Github Action Role with Assume Role Policy Attached ###
resource "aws_iam_role" "github_actions_assume_role" {
  name               = "github-actions-assume-role"
  assume_role_policy = data.aws_iam_policy_document.github_action_assume_role.json
}

### IAM Permissions for Github Action Role
data "aws_iam_policy_document" "github_action_permissions" {

  # --- BROAD PERMISSIONS FOR TERRAFORM PLAN/APPLY ---
  # Lambda
  statement {
    effect    = "Allow"
    actions   = ["lambda:*"]
    resources = ["*"]
  }

  # IAM
  statement {
    effect    = "Allow"
    actions   = ["iam:*"]
    resources = ["*"]
  }

  # S3
  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = ["*"]
  }

  # ECR transitório: necessário enquanto o Terraform ainda precisa ler e remover
  # os repositórios e lifecycle policies antigos do estado.
  statement {
    effect = "Allow"
    actions = [
      "ecr:DescribeRepositories",
      "ecr:ListTagsForResource",
      "ecr:GetLifecyclePolicy",
      "ecr:DeleteLifecyclePolicy",
      "ecr:DeleteRepository"
    ]
    resources = [
      "arn:aws:ecr:*:${var.aws_account_id}:repository/tech-floripa-certificates-*"
    ]
  }

  # SQS
  statement {
    effect    = "Allow"
    actions   = ["sqs:*"]
    resources = ["*"]
  }

  # DynamoDB
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:*"]
    resources = ["*"]
  }

  # API Gateway
  statement {
    effect    = "Allow"
    actions   = ["apigateway:*"]
    resources = ["*"]
  }

  # CloudWatch Logs
  statement {
    effect    = "Allow"
    actions   = ["logs:*"]
    resources = ["*"]
  }

  # Permissão específica para a Role atualizar sua própria política
  statement {
    effect = "Allow"
    actions = [
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]
    resources = [
      "arn:aws:iam::${var.aws_account_id}:policy/github-actions-policy"
    ]
  }
}

resource "aws_iam_policy" "github_actions_policy" {
  name        = "github-actions-policy"
  description = "Permissions for GitHub Actions to manage project resources"
  policy      = data.aws_iam_policy_document.github_action_permissions.json
}

resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.github_actions_assume_role.name
  policy_arn = aws_iam_policy.github_actions_policy.arn
}
