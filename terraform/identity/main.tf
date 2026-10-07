locals {
  repository_subject = "repo:Kun13kush@105042280/didactic@1409000562"
  oidc_provider_arn  = "arn:aws:iam::732108543574:oidc-provider/token.actions.githubusercontent.com"

  environments = {
    dev = {
      github_environment = "dev"
      resource_name      = "finzla-dev"
    }
    prod = {
      github_environment = "production"
      resource_name      = "finzla-prod"
    }
  }
}

resource "aws_iam_role" "deploy" {
  for_each = local.environments

  name                 = "${each.value.resource_name}-github-deploy"
  max_session_duration = 3600

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = local.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          "token.actions.githubusercontent.com:sub" = "${local.repository_subject}:environment:${each.value.github_environment}"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "deploy" {
  for_each = local.environments

  name = "application-deployment"
  role = aws_iam_role.deploy[each.key].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ECRAuthentication"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "PushAndReadApplicationImage"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeImages"
        ]
        Resource = "arn:aws:ecr:eu-west-2:732108543574:repository/${each.value.resource_name}"
      },
      {
        Sid    = "ApplicationTaskDefinitions"
        Effect = "Allow"
        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition"
        ]
        Resource = "arn:aws:ecs:eu-west-2:732108543574:task-definition/${each.value.resource_name}:*"
      },
      {
        Sid      = "ReadApplicationService"
        Effect   = "Allow"
        Action   = ["ecs:DescribeServices"]
        Resource = "arn:aws:ecs:eu-west-2:732108543574:service/${each.value.resource_name}/${each.value.resource_name}"
      },
      {
        Sid      = "DeployApplicationService"
        Effect   = "Allow"
        Action   = ["ecs:UpdateService"]
        Resource = "arn:aws:ecs:eu-west-2:732108543574:service/${each.value.resource_name}/${each.value.resource_name}"
        Condition = {
          ArnLike = {
            "ecs:task-definition" = "arn:aws:ecs:eu-west-2:732108543574:task-definition/${each.value.resource_name}:*"
          }
        }
      },
      {
        Sid      = "PassOnlyExecutionRole"
        Effect   = "Allow"
        Action   = ["iam:PassRole"]
        Resource = "arn:aws:iam::732108543574:role/${each.value.resource_name}-ecs-execution"
        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      },
      {
        Sid      = "VerifyTargetHealth"
        Effect   = "Allow"
        Action   = ["elasticloadbalancing:DescribeTargetHealth"]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "eu-west-2"
          }
        }
      }
    ]
  })
}

output "deployment_role_arns" {
  value = {
    for environment, role in aws_iam_role.deploy :
    environment => role.arn
  }
}
