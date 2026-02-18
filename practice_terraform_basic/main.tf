# 1. 创建 VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true # 开启 DNS 主机名，方便之后访问
  
  tags = {
    Name = "practice-vpc"
  }
}

# 2. 创建互联网网关 (IGW) - 相当于给 VPC 装个“大门”，让它能连外网
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# 3. 创建子网 1 (Sub1) - 位于东京 A 区
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true # 自动分配公网 IP，方便你练习时连接

  tags = {
    Name = "subnet-1"
  }
}

# 4. 创建子网 2 (Sub2) - 位于东京 C 区
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1c"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet-2"
  }
}

# 5. 创建路由表并关联 - 告诉子网流量怎么出门（去往 0.0.0.0/0 的流量走 IGW）
resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.rt.id
}

# 6. 创建安全组 (Firewall) - 允许 SSH (22端口) 访问
resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 生产环境建议只填你自己的 IP
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 7. 自动获取最新的 Amazon Linux 2023 镜像 ID
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
}

# 8. 创建 VM1 (在 Sub1)
resource "aws_instance" "vm1" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sub1.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = { Name = "VM1-Sub1" }
}

# 9. 创建 VM2 (在 Sub2)
resource "aws_instance" "vm2" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.sub2.id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]

  tags = { Name = "VM2-Sub2" }
}