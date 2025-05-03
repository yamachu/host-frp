# ECR VPCエンドポイント（Interface Endpoint）
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.vpc.private_subnets
  security_group_ids = [aws_security_group.ecs.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  subnet_ids        = module.vpc.private_subnets
  security_group_ids = [aws_security_group.ecs.id]
  private_dns_enabled = true
}

# S3はGateway型
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = module.vpc.private_route_table_ids
}
# VPC, サブネット, IGW, NATGW, ルートテーブル
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"
  name = "frp-vpc"
  cidr = "10.0.0.0/16"
  azs             = ["ap-northeast-1a", "ap-northeast-1c"]
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]
  enable_nat_gateway = true
  single_nat_gateway = true
  enable_dns_hostnames = true
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "frp-cluster"
}

# Security Group for NLB
resource "aws_security_group" "nlb" {
  name        = "frp-nlb-sg"
  description = "Allow TCP 7000 and 8443"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 7000
    to_port     = 7000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# NLB
resource "aws_lb" "main" {
  name               = "frp-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.nlb.id]
}

# NLBリスナー（TCP 7000）
resource "aws_lb_listener" "tcp_7000" {
  load_balancer_arn = aws_lb.main.arn
  port              = 7000
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frp_7000.arn
  }
}

# NLBリスナー（TCP 8443）
resource "aws_lb_listener" "tcp_8443" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frp_8443.arn
  }
}

# NLBリスナー（TCP 8080）
resource "aws_lb_listener" "tcp_8080" {
  load_balancer_arn = aws_lb.main.arn
  port              = 8080
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frp_8080.arn
  }
}

# ターゲットグループ（ECSタスクの7000ポート）
resource "aws_lb_target_group" "frp_7000" {
  name        = "frp-tg-7000"
  port        = 7000
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

# ターゲットグループ（ECSタスクの8443ポート）
resource "aws_lb_target_group" "frp_8443" {
  name        = "frp-tg-8443"
  port        = 8443
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

# ターゲットグループ（ECSタスクの8080ポート）
resource "aws_lb_target_group" "frp_8080" {
  name        = "frp-tg-8080"
  port        = 8080
  protocol    = "TCP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

# ECSタスク定義
resource "aws_ecs_task_definition" "frp" {
  family                   = "frp-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn = var.host-frp_ecs_task_execution_role_arn
  container_definitions = jsonencode([
    {
      name      = "frp"
      image     = var.ecr_image_url
      portMappings = [
        { containerPort = 7000, hostPort = 7000, protocol = "tcp" },
        { containerPort = 8443, hostPort = 8443, protocol = "tcp" },
        { containerPort = 8080, hostPort = 8080, protocol = "tcp" }
      ]
      essential = true
    }
  ])
  runtime_platform {
    cpu_architecture = "ARM64"
    operating_system_family = "LINUX"
  }
}

# ECSセキュリティグループ
resource "aws_security_group" "ecs" {
  name        = "frp-ecs-sg"
  description = "Allow NLB to ECS"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 7000
    to_port         = 7000
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
  }
  ingress {
    from_port       = 8443
    to_port         = 8443
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
  }
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.nlb.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECSサービス
resource "aws_ecs_service" "frp" {
  name            = "frp-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.frp.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = module.vpc.private_subnets
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frp_7000.arn
    container_name   = "frp"
    container_port   = 7000
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frp_8443.arn
    container_name   = "frp"
    container_port   = 8443
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.frp_8080.arn
    container_name   = "frp"
    container_port   = 8080
  }
  depends_on = [aws_lb_listener.tcp_7000, aws_lb_listener.tcp_8443, aws_lb_listener.tcp_8080]
}
