# modules/flashsale/main.tf

# 1. Redis for ultra-fast session & inventory management
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.env}-flashsale-redis"
  engine               = "redis"
  node_type            = "cache.t4g.medium"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  security_group_ids   = [aws_security_group.redis_sg.id]
}

# 2. Aurora Serverless v2 for the persistent Order data
resource "aws_rds_cluster" "aurora" {
  cluster_identifier      = "${var.env}-flashsale-db"
  # FIX: Change "aws-rds-postgresql" to "aurora-postgresql"
  engine                  = "aurora-postgresql" 
  engine_mode             = "provisioned"
  engine_version          = "15.6"
  database_name           = "flashsale"
  master_username         = "adminuser"
  master_password         = var.db_password
  vpc_security_group_ids  = [aws_security_group.db_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.aurora.name

  serverlessv2_scaling_configuration {
    max_capacity = 16.0
    min_capacity = 0.5
  }
}

# 3. Application Load Balancer
resource "aws_lb" "alb" {
  name               = "${var.env}-flashsale-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnets
}

# Create a Group for Aurora
resource "aws_db_subnet_group" "aurora" {
  name       = "${var.env}-aurora-subnet-group"
  subnet_ids = var.private_subnets # This takes the LIST
}

# Create a Group for Redis
resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.env}-redis-subnet-group"
  subnet_ids = var.private_subnets # This takes the LIST
}

resource "aws_lb_listener" "test" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Flash Sale System Live - Waiting for App"
      status_code  = "200"
    }
  }
}