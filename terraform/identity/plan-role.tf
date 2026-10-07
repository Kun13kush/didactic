resource "aws_iam_role" "plan" {
  name                 = "finzla-dev-github-plan"
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
          "token.actions.githubusercontent.com:sub" = "${local.repository_subject}:environment:terraform-plan"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "plan" {
  name = "read-dev-infrastructure-and-lock-state"
  role = aws_iam_role.plan.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ListStateKeys"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::finzla-tfstate-732108543574-eu-west-2"
      },
      {
        Sid      = "ReadDevState"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::finzla-tfstate-732108543574-eu-west-2/dev/terraform.tfstate"
      },
      {
        Sid      = "DevStateLock"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::finzla-tfstate-732108543574-eu-west-2/dev/terraform.tfstate.tflock"
      },
      {
        Sid    = "ReadRegionalConfiguration"
        Effect = "Allow"
        Action = [
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeNatGateways",
          "ec2:DescribeAddresses",
          "ec2:DescribeAddressesAttribute",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSecurityGroupRules",
          "ec2:DescribeTags",
          "ec2:DescribeAvailabilityZones",
          "logs:DescribeLogGroups",
          "logs:ListTagsForResource",
          "elasticloadbalancing:DescribeLoadBalancers",
          "elasticloadbalancing:DescribeLoadBalancerAttributes",
          "elasticloadbalancing:DescribeTargetGroups",
          "elasticloadbalancing:DescribeTargetGroupAttributes",
          "elasticloadbalancing:DescribeListeners",
          "elasticloadbalancing:DescribeListenerAttributes",
          "elasticloadbalancing:DescribeTags"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "eu-west-2"
          }
        }
      },
      {
        Sid      = "ReadDevRepository"
        Effect   = "Allow"
        Action   = ["ecr:DescribeRepositories", "ecr:ListTagsForResource"]
        Resource = "arn:aws:ecr:eu-west-2:732108543574:repository/finzla-dev"
      },
      {
        Sid    = "ReadDevECS"
        Effect = "Allow"
        Action = [
          "ecs:DescribeClusters",
          "ecs:DescribeServices",
          "ecs:DescribeTaskDefinition",
          "ecs:ListTagsForResource"
        ]
        Resource = [
          "arn:aws:ecs:eu-west-2:732108543574:cluster/finzla-dev",
          "arn:aws:ecs:eu-west-2:732108543574:service/finzla-dev/finzla-dev",
          "arn:aws:ecs:eu-west-2:732108543574:task-definition/finzla-dev:*"
        ]
      },
      {
        Sid    = "ReadDevExecutionRole"
        Effect = "Allow"
        Action = [
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies"
        ]
        Resource = "arn:aws:iam::732108543574:role/finzla-dev-ecs-execution"
      },
      {
        Sid      = "ReadDevCertificate"
        Effect   = "Allow"
        Action   = ["acm:DescribeCertificate", "acm:ListTagsForCertificate"]
        Resource = "arn:aws:acm:eu-west-2:732108543574:certificate/b336f736-7255-4b8b-93f6-0761208cb0ae"
      }
    ]
  })
}
