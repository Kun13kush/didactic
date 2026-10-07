data "aws_region" "current" {}

resource "aws_security_group" "app" {
  name_prefix = "${var.name}-ecs-"
  description = "Private application tasks; ALB ingress added separately."
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-ecs"
  }
}

resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS egress through NAT for ECR and CloudWatch."
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_ecs_task_definition" "app" {
  family                   = var.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([{
    name           = "app"
    image          = "${aws_ecr_repository.app.repository_url}@${var.image_digest}"
    essential      = true
    mountPoints    = []
    systemControls = []
    volumesFrom    = []
    user           = "10001:10001"

    readonlyRootFilesystem = true

    linuxParameters = {
      capabilities = {
        add  = []
        drop = ["ALL"]
      }
    }

    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
      protocol      = "tcp"
    }]

    environment = [
      {
        name  = "APP_ENV"
        value = var.environment
      },
      {
        name  = "APP_VERSION"
        value = var.app_version
      }
    ]

    healthCheck = {
      command = [
        "CMD",
        "python",
        "-c",
        "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3).close()"
      ]
      interval    = 30
      timeout     = 5
      retries     = 3
      startPeriod = 10
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.app.name
        awslogs-region        = data.aws_region.current.region
        awslogs-stream-prefix = "app"
      }
    }
  }])
}

resource "aws_ecs_service" "app" {
  name            = var.name
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 60

  load_balancer {
    target_group_arn = aws_lb_target_group.app.arn
    container_name   = "app"
    container_port   = 8000
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  wait_for_steady_state              = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role_policy.ecs_execution,
    aws_vpc_security_group_egress_rule.https,
    aws_lb_listener.https,
    aws_vpc_security_group_egress_rule.alb_to_app,
    aws_vpc_security_group_ingress_rule.app_from_alb
  ]
}

output "ecs_service_name" {
  value = aws_ecs_service.app.name
}

output "ecs_security_group_id" {
  value = aws_security_group.app.id
}
