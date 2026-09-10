locals {
  common_tags = {
    Project     = "TechNova"
    Environment = "development"
    ManagedBy   = "Terraform"
    Owner       = var.owner_ra
  }

  public_subnets = {
    public-a = { cidr = "10.0.1.0/24", az_index = 0 }
    public-b = { cidr = "10.0.3.0/24", az_index = 1 }
  }

  private_subnets = {
    private-a = { cidr = "10.0.2.0/24", az_index = 0 }
    private-b = { cidr = "10.0.4.0/24", az_index = 1 }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_vpc" "technova" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = { Name = "technova-vpc" }
}

resource "aws_subnet" "public" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.technova.id
  cidr_block              = each.value.cidr
  availability_zone       = data.aws_availability_zones.available.names[each.value.az_index]
  map_public_ip_on_launch = true

  tags = { Name = "technova-subnet-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id                  = aws_vpc.technova.id
  cidr_block              = each.value.cidr
  availability_zone       = data.aws_availability_zones.available.names[each.value.az_index]
  map_public_ip_on_launch = false

  tags = { Name = "technova-subnet-${each.key}" }
}

resource "aws_internet_gateway" "technova" {
  vpc_id = aws_vpc.technova.id
  tags   = { Name = "technova-igw" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.technova.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.technova.id
  }

  tags = { Name = "technova-rt-public" }
}

resource "aws_default_route_table" "private" {
  default_route_table_id = aws_vpc.technova.default_route_table_id
  tags                   = { Name = "technova-rt-private-default" }
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "api" {
  name        = "technova-api-sg"
  description = "Acesso SSH e API Node.js"
  vpc_id      = aws_vpc.technova.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "API Node.js"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Todo trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "technova-api-sg" }
}

resource "aws_security_group" "db" {
  name        = "technova-db-sg"
  description = "PostgreSQL acessivel apenas pela VPC"
  vpc_id      = aws_vpc.technova.id

  ingress {
    description = "PostgreSQL interno"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.technova.cidr_block]
  }

  egress {
    description = "Todo trafego de saida"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "technova-db-sg" }
}

resource "tls_private_key" "technova" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "technova" {
  key_name   = "technova-key-${var.owner_ra}"
  public_key = tls_private_key.technova.public_key_openssh
  tags       = { Name = "technova-key" }
}

resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.technova.private_key_pem
  filename        = "${path.module}/technova-key.pem"
  file_permission = "0600"
}

data "aws_iam_policy_document" "ec2_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "technova-ec2-role-${var.owner_ra}"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json
  tags               = { Name = "technova-ec2-role" }
}

resource "aws_iam_role_policy_attachment" "s3_read_only" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "technova-ec2-profile-${var.owner_ra}"
  role = aws_iam_role.ec2.name
  tags = { Name = "technova-ec2-profile" }
}

resource "aws_instance" "api" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public["public-a"].id
  vpc_security_group_ids      = [aws_security_group.api.id]
  key_name                    = aws_key_pair.technova.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    repository_url = var.repository_url
  })

  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
    tags        = merge(local.common_tags, { Name = "technova-api-root-volume" })
  }

  depends_on = [
    aws_internet_gateway.technova,
    aws_iam_role_policy_attachment.s3_read_only
  ]

  tags = { Name = "technova-api-ec2" }
}
