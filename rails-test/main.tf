provider "aws" {
  region = "ap-northeast-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "vpc-for-task-manager"
  }
}

resource "aws_subnet" "public_1a" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1a"

  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "subnet-for-task-manager-1"
  }
}

resource "aws_subnet" "public_1c" {
  vpc_id = aws_vpc.main.id

  availability_zone = "ap-northeast-1c"

  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "subnet-for-task-manager-2"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "igw-for-task-manager"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "route-table-for-task-manager"
  }
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id = aws_route_table.public.id
  gateway_id = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_1a" {
  subnet_id = aws_subnet.public_1a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id = aws_subnet.public_1c.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "main" {
  name = "task-manager-first-sg"
  description = "task-manager first sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "inbound_http" {
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "inbound_ssh" {
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "inbound_self" {
  type = "ingress"
  from_port = 3306
  to_port = 3306
  protocol = "tcp"
  source_security_group_id = aws_security_group.main.id
  security_group_id = aws_security_group.main.id
}

resource "aws_security_group_rule" "outbound_http" {
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.main.id
}

resource "aws_ami" "main" {
  ena_support = true
  name = "amzn2-ami-hvm-2.0.20201126.0-x86_64-gp2"
  description = "Amazon Linux 2 AMI 2.0.20201126.0 x86_64 HVM gp2"
  root_device_name = "/dev/xvda"
  virtualization_type = "hvm"
}

resource "aws_instance" "main" {
  ami = aws_ami.main.id
  instance_type = "t2.nano"
  key_name = "key-for-task-manager"
  subnet_id = aws_subnet.public_1a.id
  associate_public_ip_address = true
  disable_api_termination = true
  tags = {
    Name = "ec2-for-task-manager"
  }
}

resource "aws_db_subnet_group" "main" {
  name = "db-subnet-for-task-manager"
  description = "task-manager"
  subnet_ids = [aws_subnet.public_1a.id, aws_subnet.public_1c.id]
}

resource "aws_db_instance" "main" {
  instance_class = "db.t2.micro"
  max_allocated_storage = 1000
  vpc_security_group_ids = [aws_security_group.main.id]
  db_subnet_group_name = aws_db_subnet_group.main.name
  copy_tags_to_snapshot = true
  skip_final_snapshot = true
}
