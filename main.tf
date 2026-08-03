

provider "aws" {
  region = var.aws_region
}

# ============================================================
# DATA SOURCES
# ============================================================

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# ============================================================
# SECURITY GROUPS
# ============================================================

resource "aws_security_group" "ansible_controller_sg" {
  name        = "ansible-controller-sg"
  description = "Allow SSH from my IP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # tighten to your IP later: "YOUR_IP/32"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ansible-controller-sg" }
}

resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"
  description = "Allow SSH from controller and HTTP from anywhere"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "SSH from Ansible controller"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ansible_controller_sg.id]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "nginx-sg" }
}

# ============================================================
# IAM ROLE FOR CONTROLLER (dynamic inventory needs EC2 read access)
# ============================================================

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ansible_controller_role" {
  name               = "ansible-controller-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ec2_readonly" {
  role       = aws_iam_role.ansible_controller_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ansible_controller_profile" {
  name = "ansible-controller-profile"
  role = aws_iam_role.ansible_controller_role.name
}

# ============================================================
# ANSIBLE CONTROLLER
# ============================================================

resource "aws_instance" "ansible_controller" {
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = "t3.micro"
  subnet_id                   = data.aws_subnets.default.ids[0]
  vpc_security_group_ids      = [aws_security_group.ansible_controller_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.ansible_controller_profile.name

  tags = { Name = "ansible-controller" }
}

# ============================================================
# 3 NGINX TARGET SERVERS
# ============================================================

resource "aws_instance" "nginx_server" {
  count                       = var.instance_count
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = data.aws_subnets.default.ids[count.index % length(data.aws_subnets.default.ids)]
  vpc_security_group_ids      = [aws_security_group.nginx_sg.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = "nginx-server-${count.index + 1}"
    Role = "webserver"
  }
}

# ============================================================
# OUTPUTS
# ============================================================

output "controller_public_ip" {
  value = aws_instance.ansible_controller.public_ip
}

output "nginx_public_ips" {
  value = aws_instance.nginx_server[*].public_ip
}