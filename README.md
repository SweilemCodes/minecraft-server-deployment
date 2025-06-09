# Minecraft Server Deployment on AWS with Terraform and AWS CLI

## Background
**What will we do?**
In this project, we will automate the deployment of a Minecraft server on an AWS EC2 instance using Infrastructure as Code (IaC) principles. The goal is to create a fully hands-off deployment pipeline that provisions cloud infrastructure, installs required software, and launches a functional Minecraft server without any manual configuration or SSH access. By the end, users will have a reproducible setup that enables public access to a Minecraft server that persists across instance reboots.

**How will we do it?** 
To achieve this, we will use Terraform to define and provision AWS resources such as the EC2 instance, VPC, subnet, internet gateway, route tables, and security groups. After the infrastructure is deployed, AWS Systems Manager (SSM) will be used to remotely send shell commands to the EC2 instance. These commands will install Amazon Corretto 21 (Java runtime), download the latest Minecraft server .jar file, and configure the game server to run as a systemd service. This ensures that the Minecraft server starts automatically at boot and shuts down cleanly during system reboots. All setup steps, including AWS CLI configuration and command execution, are done locally without using the AWS Management Console or SSH, making this a secure and fully automated deployment.

---

## Requirements
**Note** This was done on MacOS Ventura 13.3. Other operating systems may have different or additional requirements.

### What will the user need to configure to run the pipeline? - overview of everything
To run the pipeline end-to-end, the user will need to complete a few local setup steps and edit configuration files. These include:

- Installing Terraform and AWS CLI version 2.
- Configuring AWS credentials locally using aws configure.
- Updating several Terraform-related files:
  
  Setting your current IP address in variables.tf to restrict access.

  Fetching the latest Amazon Linux 2023 AMI and adding it to terraform.tfvars.

  Verifying or updating the IAM instance profile in main.tf to ensure the EC2 instance has SSM access.

  Updating the Minecraft server download URL in commands.json to point to the latest version.

  Ensure the EC2 instance will have an IAM role with SSM permissions (AmazonSSMManagedInstanceCore) attached.

### What tools should be installed
- Terraform v1.7 or later - https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli
- AWS CLI version 2 - https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html


### Are there any credentials or CLI required?
In your terminal, run the following commands, replacing placeholders with your AWS credentials:
   
```plaintext 
  aws configure set aws_access_key_id <your-access-key-id>
```
```plaintext
  aws configure set aws_secret_access_key <your-secret-access-key>
```
```plaintext
  aws configure set aws_session_token <your-session-token>
``` 

### Should the user set environment variables or configure anything?

**Note:** this is for smaller setups. If you want to upgrade, you’ll need to make edits to the following defualts: instance type for more CPU and memory, VPC and subnet sizes for larger network capacity, storage volumes for faster and bigger disk space, security groups for tighter access control, and potentially add load balancing and auto-scaling to handle more players and traffic smoothly.


**File edits**
- **main.tf** - On line 99, update the iam_instance_profile value to an instance profile with SSM permissions (Resource for creating one: https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-create-iam-instance-profile.html)
- **variables.tf** - If your region isn't the default us-east-1, on line 7 change the default region to your own (e.g. us-west-2). 
- **variables.tf** - On line 43, change the default IP to your own (for security).
- **terraform.tfvars** - On line 4, update the ami. The following command should return the most up-to-date one (change region if needed -- default is us-east-1):
```plaintext
  aws ec2 describe-images \
  --owners amazon \
  --filters "Name=name,Values=al2023-ami-20*-kernel-*-x86_64" \
            "Name=architecture,Values=x86_64" \
            "Name=state,Values=available" \
            "Name=root-device-type,Values=ebs" \
            "Name=virtualization-type,Values=hvm" \
  --query 'Images | sort_by(@, &CreationDate) | [-1].{AMI:ImageId,Name:Name,Date:CreationDate}' \
  --region <your-region>
```
- **commands.json** - On line 9, update the link from this source https://www.minecraft.net/en-us/download/server to download the most up-to-date version of Minecraft.

---

## Architecture Diagram
```plaintext
        ┌───────────────────┐
        │   Your Machine    │
        │ (Terraform + AWS  │
        │      CLI v2)      │
        └────────┬──────────┘
                │
                │ Terraform applies IaC
                │ (provision AWS infra)
                │
                ▼
┌─────────────────────────────────┐
│          AWS Cloud              │
│  ┌───────────────┐              │
│  │  VPC          │              │
│  │  Subnet       │              │
│  │  Internet GW  │              │
│  │  Route Tables │              │
│  │  Security Grp │              │
│  │  EC2 Instance │              │
│  │  IAM Role(SSM)│              │
│  └───────────────┘              │
└─────────────────────────────────┘
                │
                │ AWS Systems Manager (SSM)
                │ Remote command execution
                │ (no SSH required)
                │
                ▼
┌───────────────────────────────┐
│     EC2 Instance (Amazon      │
│       Linux 2023)             │
│ - Amazon Corretto 21 (JRE)    │
│ - Minecraft Server Setup      │
│ - systemd service for server  │
└──────────────┬────────────────┘
                │
                │ Java Runtime executes Minecraft Server
                │ Accepts player connections on port 25565
                ▼
┌───────────────────────────────┐
│      Minecraft Server         │
│  - Persistent, Auto-restart   │
│  - Publicly accessible game   │
└───────────────────────────────┘

```
---

## Commands & Explanations
**Note** This was done on MacOS Ventura 13.3. Other operating systems may have different or additional steps.

### Launching Instance
1. To launch the EC2 instance we're going to install minecraft on, run the following commands:
```plaintext
  terraform init
```
```plaintext
  terraform plan
```
```plaintext
  terraform apply # Answer "yes" when prompted
```

That last command will output your IP. Take note of it. If you ever forget, you can run:
```plaintext
  aws ec2 describe-instances --instance-ids <your-instance-id> --query "Reservations[0].Instances[0].PublicIpAddress" --output text
```

### Installing and Launching Minecraft
1. First, find your instance id by running the following command. Take note of it:
```plaintext 
  aws ec2 describe-instances \
  --query "Reservations[*].Instances[*].[InstanceId,LaunchTime]" \
  --output text | sort -k2 | tail -n1 | awk '{print $1}'
```

2. Using your instance id, run the following command to setup the Minecraft server:
```plaintext 
  aws ssm send-command \
  --instance-ids "<your-instance-id>" \
  --document-name "AWS-RunShellScript" \
  --parameters file://commands.json \
  --comment "Setup Minecraft server" \
  --output text
```

**Note:** use 'q' to escape the output.

---

## Connect to Minecraft Server
1. Ensure the server is open and recognizable using the following:
```plaintext
  nmap -sV -Pn -p T:25565 <instance_public_ip> 
```

  OR    

```plaintext
  Launch Minecraft and navigate to Multiplayer -> Direct Connect -> <instance_public_ip> -> Confirm you are able to connect and the server is responsive to game actions.
```

If you don't see minecraft listed or are unable to connect, retrace your steps and see if anything was missed or misconfigured and that there were no error messages along the way.

2. Ensure Minecraft shuts downs gracefully and automatically starts up on reboot by running the following commands:
   
Reboot the server:
```plaintext
  aws ec2 reboot-instances --instance-ids <your-instance-id>
```

Wait 30-60 seconds.

Look at shutdown logs by running the following :
```plaintext
  aws ssm send-command \
  --instance-ids "<your-instance-id>" \
  --document-name "AWS-RunShellScript" \
  --comment "Check Minecraft shutdown log" \
  --parameters 'commands=["journalctl -u minecraft --no-pager -n 50"]'

```

This will give you a command ID. Wait 30-60 more seconds.

Then run:
```plaintext
  aws ssm get-command-invocation --command-id <your-command-id> --instance-id <your-instance-id> 
```


Look for the following messages in the "StandardOutputContent" section to confirm graceful shutdown:
- systemd[1]: Stopping minecraft.service - Minecraft Server...

  This means systemd initiated the stop cleanly.

- systemd[1]: minecraft.service: Deactivated successfully.

  This means the Minecraft service stopped cleanly without any errors. Systemd confirms the service shut down as expected.

- systemd[1]: Stopped minecraft.service - Minecraft Server

  Confirms the service actually stopped.

- systemd[1]: minecraft.service: Consumed X CPU time.

  Just resource usage info, but indicates a clean lifecycle end.

You should also hopefully see some messages about the server booting back up. We're going to test that the server is functional anyway.

Confirm the server was properly started with NMAP or by logging into the game:
```plaintext
  nmap -sV -Pn -p T:25565 <instance_public_ip> 
```

  OR    

```plaintext
  Launch Minecraft and navigate to Multiplayer -> Direct Connect -> <instance_public_ip> -> Confirm you are able to connect and the server is responsive to game actions.
```

You should see the server up and functional like earlier. Everything should be good to go!

## Additional Resources
**Terraform AWS Provider Docs**
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- Official documentation for Terraform's AWS provider, covering all supported AWS services and configuration examples.

**AWS Systems Manager (SSM) Overview**
- https://docs.aws.amazon.com/systems-manager/latest/userguide/what-is-systems-manager.html
- Learn how SSM works, especially for sending remote commands to EC2 without SSH.

**Amazon EC2 User Guide for Linux Instances**
- https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/
- Detailed guide on launching, connecting, and managing EC2 Linux instances.

**Minecraft Server Admin Guide (Unofficial)**
- https://minecraft.fandom.com/wiki/Tutorials/Setting_up_a_server
- A community-maintained reference for setting up and managing Minecraft servers.

**Using systemd to Manage Services**
- https://www.freedesktop.org/software/systemd/man/systemd.service.html
- Reference for creating and managing services with systemd, useful for setting up the Minecraft server daemon.

**Amazon Linux 2023 AMI Docs**
- https://docs.aws.amazon.com/linux/al2023/ug/
- Official documentation for Amazon Linux 2023, including package management, system services, and SSM usage.

---