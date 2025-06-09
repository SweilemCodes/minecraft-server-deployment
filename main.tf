# -------------------------------
# AWS PROVIDER CONFIGURATION
# -------------------------------
provider "aws" {
  region = var.aws_region   # Use the AWS region specified in the variable aws_region
}

# -------------------------------
# VPC
# -------------------------------
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block  # The IP address range for the VPC, e.g. "10.0.0.0/16"
}

# -------------------------------
# SUBNET
# -------------------------------
resource "aws_subnet" "main_subnet" {
  vpc_id                  = aws_vpc.main.id    # Associate this subnet with the VPC created above
  cidr_block              = var.subnet_cidr_block  # IP range for this subnet, e.g. "10.0.1.0/24"
  # availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true  # Automatically assign public IPs to instances launched in this subnet
  
}

# -------------------------------
# INTERNET GATEWAY
# -------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id  # Attach this Internet Gateway to the main VPC
}

# -------------------------------
# ROUTE TABLE
# -------------------------------
resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.main.id  # This route table is for the main VPC

  route {
    cidr_block = "0.0.0.0/0"          # This route sends all outbound traffic (internet-bound)
    gateway_id = aws_internet_gateway.igw.id  # Routes traffic through the internet gateway
  }
}

# -------------------------------
# ROUTE TABLE ASSOCIATION
# -------------------------------
resource "aws_route_table_association" "route_assoc" {
  subnet_id      = aws_subnet.main_subnet.id   # The subnet to associate with the route table
  route_table_id = aws_route_table.route_table.id  # The route table to use for this subnet
}

# -------------------------------
# SECURITY GROUP
# -------------------------------
resource "aws_security_group" "minecraft_sg" {
  name        = var.security_group_name   # Security group name from variable
  description = "Allow Minecraft and SSH" # Description for what this SG allows
  vpc_id      = aws_vpc.main.id           # Attach this security group to the main VPC

  # Inbound rule to allow Minecraft TCP traffic on port 25565 from anywhere
  ingress {
    from_port   = 25565                  # Minecraft server port
    to_port     = 25565                  # Single port (same as from_port)
    protocol    = "tcp"                  # TCP protocol
    cidr_blocks = ["0.0.0.0/0"]          # Allow from any IP address globally
  }


  # Inbound rule to allow SSH access on port 22, restricted by IP(s) in variable
  ingress {
    from_port   = 22                    # SSH port
    to_port     = 22                    # Single port
    protocol    = "tcp"                 # TCP protocol
    cidr_blocks = var.ssh_allowed_ips   # Restrict access to specified IP(s) for security
  }

  # Outbound rule allowing all outbound traffic to anywhere
  egress {
    from_port   = 0                    # Starting port (0 means all)
    to_port     = 0                    # Ending port (0 means all)
    protocol    = "-1"                 # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]        # Allow outbound to anywhere
  }
}

# -------------------------------
# EC2 INSTANCE
# -------------------------------

# Launch an EC2 instance to host the Minecraft server
resource "aws_instance" "minecraft" {
  ami                    = var.ami_id                  # AMI ID to use (e.g. Amazon Linux, Ubuntu)
  instance_type          = var.instance_type           # Instance size/type (e.g. t3.micro)
  subnet_id              = aws_subnet.main_subnet.id   # Place instance inside the public subnet
  # key_name               = var.key_name                # SSH key pair name for access
  vpc_security_group_ids = [aws_security_group.minecraft_sg.id]  # Attach the Minecraft security group

  iam_instance_profile = "LabInstanceProfile" # Attach IAM role via instance profile to grant permissions (e.g., SSM access) 


  associate_public_ip_address = true  # Assign a public IP to this instance for internet access

  tags = {
    Name = var.instance_name    # Tag the instance with a human-readable name
  }
}

# -------------------------------
# OUTPUTS
# -------------------------------

# Output the public IP address of the Minecraft instance after apply
output "public_ip" {
  value = aws_instance.minecraft.public_ip  # Make the public IP accessible for reference
}
