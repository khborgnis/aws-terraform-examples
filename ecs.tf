resource "aws_security_group" "ssh" {
  name   = "allow_ssh"
  vpc_id = aws_vpc.demo.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.ssh.id
  cidr_ipv4         = "${var.personal_ip}/32"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_security_group" "web" {
  name   = "allow_web"
  vpc_id = aws_vpc.demo.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_web" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = -1
}

resource "aws_key_pair" "ssh" {
  key_name   = "personal-ssh-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_iam_role" "ecs-instance" {
  name               = "ec2-instance-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2-for-ecs" {
  role       = aws_iam_role.ecs-instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2-for-ecs" {
  name = "ec2-for-ecs"
  role = aws_iam_role.ecs-instance.name
}

# Hour 4

resource "aws_launch_template" "ec2-for-ecs" {
  name = "ec2-for-ecs"

  image_id      = data.aws_ami.debian.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ssh.key_name

  instance_initiated_shutdown_behavior = "terminate"

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.ssh.id, aws_security_group.web.id]
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2-for-ecs.name
  }

  user_data = base64encode(templatefile("${path.module}/debian_user_data.sh",
    { region = data.aws_region.current.name,
  cluster_name = aws_ecs_cluster.demo.name }))
}

resource "aws_autoscaling_group" "webtier" {
  max_size = 2
  min_size = 1

  vpc_zone_identifier = tolist(aws_subnet.public[*].id)

  launch_template {
    id      = aws_launch_template.ec2-for-ecs.id
    version = aws_launch_template.ec2-for-ecs.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

resource "aws_ecs_cluster" "demo" {
  name = "demo"

  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_log_group_name = aws_cloudwatch_log_group.demo.name
      }
    }
  }
}

resource "aws_ecs_task_definition" "service" {
  family = "service"

  container_definitions = jsonencode([
    {
      name      = "rails"
      image     = "public.ecr.aws/bitnami/rails:8.0.1"
      cpu       = 100
      memory    = 400
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
      environment = [{
        name  = "RAILS_ENV"
        value = "production"
        }, {
        name  = "RAILS_SKIP_ACTIVE_RECORD"
        value = "yes"
        }, {
        name  = "RAILS_SKIP_DB_SETUP"
        value = "yes"
        }, {
        name  = "RAILS_SKIP_DB_WAIT"
        value = "yes"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "demo"
          "awslogs-region"        = "${data.aws_region.current.name}"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "demo" {
  name = "demo"
}

resource "aws_ecs_service" "demo" {
  name          = "demo-service"
  cluster       = aws_ecs_cluster.demo.id
  desired_count = 1

  task_definition = aws_ecs_task_definition.service.arn
  launch_type     = "EC2"

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Allow external changes to desired_count
  lifecycle {
    ignore_changes = [desired_count]
  }
}
