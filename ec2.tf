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
  key_name = "personal-ssh-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_iam_role" "ecs-instance" {
  name = "ec2-instance-role"
  assume_role_policy = data.aws_iam_policy_document.instance_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ec2-for-ecs" {
  role = aws_iam_role.ecs-instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ec2-for-ecs" {
  name = "ec2-for-ecs"
  role = aws_iam_role.ecs-instance.name
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.debian.id
  instance_type = "t2.micro"

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.ssh.id, aws_security_group.web.id]

  key_name = aws_key_pair.ssh.key_name

  iam_instance_profile = aws_iam_instance_profile.ec2-for-ecs.name

  user_data_replace_on_change = true
  user_data                   = <<-EOF
                #!/bin/bash

                # Update base OS software
                export DEBIAN_FRONTEND=noninteractive
                apt update
                apt-get -o Dpkg::Options::="--force-confold" dist-upgrade -q -y --force-yes

                # Add Docker's official GPG key:
                apt-get install -y curl ca-certificates curl
                install -m 0755 -d /etc/apt/keyrings
                curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
                chmod a+r /etc/apt/keyrings/docker.asc

                # Add the repository to Apt sources:
                echo \
                  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
                  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
                  tee /etc/apt/sources.list.d/docker.list > /dev/null
                apt-get update
                apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

                # Install ECS init agent
                curl https://s3.${data.aws_region.current.name}.amazonaws.com/amazon-ecs-agent-${data.aws_region.current.name}/amazon-ecs-init-latest.amd64.deb -o /tmp/ecs.deb
                dpkg -i /tmp/ecs.deb
              EOF
  tags = {
    Name = "HelloWorld"
  }
}
