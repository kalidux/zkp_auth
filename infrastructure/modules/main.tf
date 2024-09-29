provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_igw"
  }
}

# Route Table
resource "aws_route_table" "main_route" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main_route_table"
  }
}

# Subnet
resource "aws_subnet" "main" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "main_subnet"
  }
}

# Associate Route Table to Subnet
resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main_route.id
}

# Security Group for server instance
resource "aws_security_group" "allow_server" {
  name_prefix = "allow_server"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 50051
    to_port     = 50051
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows external traffic to port 50051
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows SSH access for EC2 Instance Connect
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "server_sg"
  }
}

# Security Group for client instance
resource "aws_security_group" "allow_client" {
  name_prefix = "allow_client"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 50051
    to_port     = 50051
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]  # Only allows communication with the server
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows SSH access for EC2 Instance Connect
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "client_sg"
  }
}

# EC2 Instance for the Server
resource "aws_instance" "rust_server" {
  ami                      = var.ami_id
  instance_type            = "t2.micro"
  subnet_id                = aws_subnet.main.id
  associate_public_ip_address = true  # Associates a public IP
  vpc_security_group_ids    = [aws_security_group.allow_server.id]

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -x

              # Update packages
              sudo yum update -y
 
              # Install Docker

              sudo yum install docker -y

              sudo systemctl start docker

              sudo usermod -a -G docker ec2-user 
              
              # Install EC2 Instance Connect
              sudo yum install -y ec2-instance-connect
              
              # Install Docker Compose
              sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose

              sudo chmod +x /usr/local/bin/docker-compose

              docker-compose version

              # Verify Docker and Docker Compose installation
              docker --version || echo "Docker not installed"
              docker compose version || echo "Docker Compose not installed"

              # Create shared Docker network
              docker network create zkp_network || true

              # Docker-compose configuration for the server
              cat <<EOT > /home/ec2-user/docker-compose-server.yml
              version: '3.8'
              services:
                server:
                  image: kalidux/zkp_server:latest
                  container_name: zkp_server
                  ports:
                    - "50051:50051"
                  networks:
                    - zkp_network

              networks:
                zkp_network:
                  external: true
              EOT

              sudo docker-compose -f /home/ec2-user/docker-compose-server.yml up -d || echo "Docker Compose failed to start"
            EOF

  tags = {
    Name = "rust_server_instance"
  }
}

# Elastic IP for the Server
resource "aws_eip" "server_eip" {
  instance = aws_instance.rust_server.id

  tags = {
    Name = "server_eip"
  }
}

# EC2 Instance for the Client
resource "aws_instance" "rust_client" {
  ami                      = var.ami_id
  instance_type            = "t2.micro"
  subnet_id                = aws_subnet.main.id
  associate_public_ip_address = true  # Associates a public IP
  vpc_security_group_ids    = [aws_security_group.allow_client.id]

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1
              set -x

              # Update packages
              sudo yum update -y

              # Install Docker

              sudo yum install docker -y

              sudo systemctl start docker

              sudo usermod -a -G docker ec2-user 

              # Install EC2 Instance Connect
              sudo yum install -y ec2-instance-connect
              
              # Install Docker Compose
              sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose

              sudo chmod +x /usr/local/bin/docker-compose

              docker-compose version

              # Add ec2-user to Docker group
              sudo usermod -aG docker ec2-user

              # Verify Docker and Docker Compose installation
              docker --version || echo "Docker not installed"
              docker compose version || echo "Docker Compose not installed"

              # Join the shared Docker network
              docker network create zkp_network || true

              # Docker-compose configuration for the client
              cat <<EOT > /home/ec2-user/docker-compose-client.yml
              version: '3.8'
              services:
                client:
                  image: kalidux/zkp_client:latest
                  container_name: zkp_client
                  networks:
                    zkp_network:
                      aliases:
                        - zkp_server  # Creates an alias zkp_server for the server's public IP
                  extra_hosts:
                    - "zkp_server:${aws_eip.server_eip.public_ip} "  # Adds the public IP as an alias because docker network does not support external DNS resolution

              networks:
                zkp_network:
                  external: true
              EOT

              sudo docker-compose -f /home/ec2-user/docker-compose-client.yml up -d || echo "Docker Compose failed to start"
            EOF

  tags = {
    Name = "rust_client_instance"
  }
}

# Output the Server Elastic IP
output "server_eip" {
  value = aws_eip.server_eip.public_ip
}
