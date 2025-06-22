# Placeholder for EC2 instance configuration 

data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Security Group for Jenkins
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Security group for Jenkins EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to the world. Restrict to your IP for production.
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

  tags = {
    Name = "jenkins-sg"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Security Group for SonarQube & Trivy
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "tools_sg" {
  name        = "tools-sg"
  description = "Security group for SonarQube and Trivy EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to the world. Restrict to your IP for production.
  }

  ingress {
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tools-sg"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# Security Group for Monitoring
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_security_group" "monitoring_sg" {
  name        = "monitoring-sg"
  description = "Security group for Monitoring EC2 instance"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to the world. Restrict to your IP for production.
  }

  ingress {
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "monitoring-sg"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EC2 Instance for Jenkins
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "jenkins_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.jenkins_instance_type
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = "devops_jenkins"

  root_block_device {
    volume_size = 16 # Increased from 8GB to 16GB
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              # Install Jenkins
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              sudo amazon-linux-extras install java-openjdk11 -y
              sudo yum install jenkins -y
              sudo service jenkins start
              # Install git
              sudo yum install git -y
              EOF

  tags = {
    Name = "Jenkins-Server"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EC2 Instance for SonarQube & Trivy
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "tools_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.tools_instance_type
  subnet_id              = aws_subnet.public[1].id
  vpc_security_group_ids = [aws_security_group.tools_sg.id]
  key_name               = "devops_jenkins"

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              # Install Docker for SonarQube
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              # Install SonarQube (using Docker)
              docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community
              # Install Trivy
              sudo rpm -ivh https://github.com/aquasecurity/trivy/releases/download/v0.30.0/trivy_0.30.0_Linux-64bit.rpm
              EOF

  tags = {
    Name = "Tools-Server"
  }
}

# ---------------------------------------------------------------------------------------------------------------------
# EC2 Instance for Monitoring
# ---------------------------------------------------------------------------------------------------------------------
resource "aws_instance" "monitoring_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.monitoring_instance_type
  subnet_id              = aws_subnet.public[1].id # Using the second public subnet
  vpc_security_group_ids = [aws_security_group.monitoring_sg.id]
  key_name               = "devops_jenkins"

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              # Install Docker
              sudo amazon-linux-extras install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              
              # Run Prometheus and Grafana using Docker
              # Note: This is a basic setup. For production, you'd use persistent storage and a proper configuration.
              docker run -d --name prometheus -p 9090:9090 prom/prometheus
              docker run -d --name grafana -p 3000:3000 grafana/grafana
              EOF

  tags = {
    Name = "Monitoring-Server"
  }
}

output "jenkins_server_public_ip" {
  description = "Public IP address of the Jenkins server."
  value       = aws_instance.jenkins_instance.public_ip
}

output "tools_server_public_ip" {
  description = "Public IP address of the Tools server."
  value       = aws_instance.tools_instance.public_ip
}

output "monitoring_server_public_ip" {
  description = "Public IP address of the Monitoring server."
  value       = aws_instance.monitoring_instance.public_ip
} 