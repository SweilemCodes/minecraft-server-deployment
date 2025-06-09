# -------------------------------
# REGION TO DEPLOY RESOURCES IN
# -------------------------------
variable "aws_region" {
  description = "AWS region to deploy to" # Used by the AWS provider to know where to create resources
  type        = string                    # Must be a string (e.g., "us-east-1", "us-west-2")
  default     = "us-east-1"               # Default region is US East (N. Virginia)
}

# -------------------------------
# VPC CONFIGURATION
# -------------------------------
variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"     # IP address range for the entire VPC network
  type        = string                       # Example: "10.0.0.0/16" gives 65,536 addresses
  default     = "10.0.0.0/16"                # Default large private IP block
}

# -------------------------------
# SUBNET CONFIGURATION
# -------------------------------
variable "subnet_cidr_block" {
  description = "CIDR block for the subnet"  # Subsection of the VPC for specific resources
  type        = string                       # Must be within the VPC CIDR block
  default     = "10.0.1.0/24"                # Gives 256 IPs; plenty for a small deployment
}

# -------------------------------
# SECURITY GROUP NAMING
# -------------------------------
variable "security_group_name" {
  description = "Name for the security group" # Human-readable name used to label the SG in AWS
  type        = string                        # Must be a string
  default     = "minecraft_sg"                # Default to something Minecraft-specific
}

# -------------------------------
# IP RANGES ALLOWED TO SSH
# -------------------------------
variable "ssh_allowed_ips" {
  description = "CIDR blocks allowed to SSH (for security)"  # Limit who can access your server
  type        = list(string)                                 # Must be a list of CIDR strings
  default     = ["0.0.0.0/0"]                        # Replace with your own IP address!
}

# -------------------------------
# AMI ID TO USE FOR EC2 INSTANCE
# -------------------------------
variable "ami_id" {
  description = "AMI ID for the EC2 instance" # This should match the region (e.g., Ubuntu, Amazon Linux)
  type        = string                        # User must supply this or use a data source to look it up
  # Example: "ami-0abcdef1234567890"
}

# -------------------------------
# EC2 INSTANCE TYPE
# -------------------------------
variable "instance_type" {
  description = "EC2 instance type"  # Controls CPU, RAM, networking, etc.
  type        = string               # Examples: "t2.micro", "t3.medium", "m5.large"
  default     = "t3.medium"          # Good balance of resources for a Minecraft server
}

# -------------------------------
# SSH KEY PAIR NAME - Not in Use
# -------------------------------
# variable "key_name" { 
#  description = "Name of the AWS key pair"    # Used to SSH into the EC2 instance
#  type        = string                        
# }

# -------------------------------
# TAG NAME FOR THE INSTANCE
# -------------------------------
variable "instance_name" {
  description = "Tag name for the EC2 instance" # Appears in the AWS Console to help identify the instance
  type        = string                          # Tag value must be a string
  default     = "MinecraftServer"               # Useful default tag
}
