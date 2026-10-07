moved {
  from = aws_ecr_repository.app
  to   = module.platform.aws_ecr_repository.app
}

moved {
  from = aws_ecs_cluster.app
  to   = module.platform.aws_ecs_cluster.app
}

moved {
  from = aws_cloudwatch_log_group.app
  to   = module.platform.aws_cloudwatch_log_group.app
}

moved {
  from = aws_iam_role.ecs_execution
  to   = module.platform.aws_iam_role.ecs_execution
}

moved {
  from = aws_iam_role_policy.ecs_execution
  to   = module.platform.aws_iam_role_policy.ecs_execution
}
