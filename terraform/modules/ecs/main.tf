# Trust policy for ECS execution and task roles (1/5)
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# ECS execution role + policy (2/5):
resource "aws_iam_role" "ecs_execution_role" {
  name               = "${var.name_prefix}-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags = {
    Environment = var.environment
    Name        = "${var.name_prefix}-ecs-execution-role"
  }
}

# ECS task role + policy (3/5):
resource "aws_iam_role" "ecs_task_role" {
  name               = "${var.name_prefix}-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags = {
    Environment = var.environment
    Name        = "${var.name_prefix}-ecs-task-role"
  }
}

# Attach the AmazonECSTaskExecutionRolePolicy to the ECS execution role (4/5)
resource "aws_iam_role_policy_attachment" "ecs_execution_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach the AmazonSSMManagedInstanceCore policy to the ECS task role (5/5)
resource "aws_iam_role_policy_attachment" "ecs_task_ssm_policy" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch Log Group for ECS Tasks
resource "aws_cloudwatch_log_group" "ecs_tasks" {
  name              = "/ecs/${var.name_prefix}-tasks"
  retention_in_days = 7
}

# ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = "${var.name_prefix}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.name_prefix}-cluster"
    Environment = var.environment
  }
}

# ECS Service Discovery (Cloud Map) for Headscale
resource "aws_service_discovery_private_dns_namespace" "internal" {
  name = "${var.name_prefix}.internal"
  vpc  = var.vpc_id
}

resource "aws_service_discovery_service" "headscale" {
  name = "headscale"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.internal.id
    dns_records {
      ttl  = 10
      type = "A"
    }
  }
}


# ECS Task Definition
resource "aws_ecs_task_definition" "headscale_task" {
  family                   = "${var.name_prefix}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.name_prefix}-container"
      image     = "${var.ecr_repository_url}:${var.image_tag}"
      essential = true
      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        },
        {
          containerPort = 41641
          protocol      = "udp"
        },

        {
          containerPort = 9090
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_tasks.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "${var.name_prefix}"
        }
      }
    }
  ])
}

# ECS Security Group
resource "aws_security_group" "ecs_tasks" {
  name        = "${var.name_prefix}-ecs-sg"
  description = "Security group for ECS tasks"
  vpc_id      = var.vpc_id
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 41641
    to_port     = 41641
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = var.environment
    Name        = "${var.name_prefix}-ecs-sg"
  }
}

# ECS Service
resource "aws_ecs_service" "headscale_service" {
  name                   = "${var.name_prefix}-service"
  cluster                = aws_ecs_cluster.cluster.id
  task_definition        = aws_ecs_task_definition.headscale_task.arn
  desired_count          = 1
  launch_type            = "FARGATE"
  enable_execute_command = true

  network_configuration {
    subnets          = var.private_subnet_id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = var.tg_controlplane_arn
    container_name   = "${var.name_prefix}-container"
    container_port   = 8080
  }
  load_balancer {
    target_group_arn = var.tg_wireguard_arn
    container_name   = "${var.name_prefix}-container"
    container_port   = 41641
  }

  service_registries {
    registry_arn = aws_service_discovery_service.headscale.arn
  }


  tags = {
    Environment = var.environment
    Name        = "${var.name_prefix}-service"
  }
}
