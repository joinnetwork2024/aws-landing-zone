# 1. Security Group for the Application Load Balancer (Public Access)
resource "aws_security_group" "alb_sg" {
  name   = "${var.env}-flashsale-alb-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows world to access the sale
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2. Security Group for Redis (Internal Access)
resource "aws_security_group" "redis_sg" {
  name   = "${var.env}-flashsale-redis-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Only ALB/App can talk to Redis
  }
}

# 3. Security Group for Aurora PostgreSQL (Internal Access)
resource "aws_security_group" "db_sg" {
  name   = "${var.env}-flashsale-db-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Only ALB/App can talk to DB
  }
}

