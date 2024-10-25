# Data source to find the latest AMI for Kubernetes
data "aws_ami" "k8s_control_plane" {
  most_recent = true
  owners = ["602401143452"] # This is the owner ID for Amazon EKS optimized AMIs
  filter {
    name   = "name"
    values = ["amazon-eks-node-1.30-v20240514"] # Adjust the pattern based on the naming convention of your AMIs
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Key operation

resource "tls_private_key" "k8s" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "k8s" {
  key_name   = "k8s"
  public_key = tls_private_key.k8s.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "k8s_private_key" {
  content  = tls_private_key.k8s.private_key_pem
  #content = tls_private_key.k8s.public_key_openssh
  filename = "${path.module}/k8s_private_key.pem" # Change this path if necessary
  #sensitive = true # Mark as sensitive to avoid displaying the content in the plan output
}

# Create an EC2 instance
resource "aws_instance" "k8s_node" {
  count         = local.node_count
  ami           = "ami-00a07c934c659db39" # data.aws_ami.k8s_control_plane.id
  instance_type = "t4g.micro"
  subnet_id     = data.aws_subnets.main.ids[count.index] # aws_subnet.public[count.index].id
  key_name      = aws_key_pair.k8s.key_name #"${local.env}_${local.project_name}_k8s_key_pair" 
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm.name
  vpc_security_group_ids = [aws_security_group.sg_main.id]
  #security_groups = [aws_security_group.sg_main.name]
# security_groups - (Optional, EC2-Classic and default VPC only) List of security group names to associate with.
# NOTE:
# If you are creating Instances in a VPC, use vpc_security_group_ids instead.
  # vpc_security_group_ids = [aws_security_group.server_ssh_access.id]
  # security_groups    = [aws_security_group.sg_main.name]
  associate_public_ip_address = true
  private_ip = count.index == 0 ? replace(data.aws_subnet.subnet_list[data.aws_subnets.main.ids[count.index]].cidr_block,"0/${split("/", data.aws_subnet.subnet_list[data.aws_subnets.main.ids[count.index]].cidr_block)[1]}","10") : null
  #disable_api_termination = false
  user_data = templatefile("K3S_INSTALL.sh", {
    count_index = count.index
    first_node  = replace(data.aws_subnet.subnet_list[data.aws_subnets.main.ids[0]].cidr_block,"0/${split("/", data.aws_subnet.subnet_list[data.aws_subnets.main.ids[0]].cidr_block)[1]}","10")
  })
  root_block_device {
    volume_size = 30  
    volume_type = "gp2" 
  }
  tags = {
    Name = "${local.env}_${local.project_name}_k8s_node_xyz"
  }
}

output "k8s_node_public_ips" {
  value = aws_instance.k8s_node[*].public_ip
  description = "Public IP addresses of the Kubernetes nodes"
}

output "k8s_node_ids" {
  value = aws_instance.k8s_node[*].id
  description = "Instance ID of the Kubernetes nodes"
}

# Create a random string to append to the node name
resource "random_string" "node_suffix" {
  count = local.node_count
  length  = 5 
  special = false 
  upper   = false 
  numeric  = true
}


# Create a Security Group
resource "aws_security_group" "sg_main" {
  name        = "${local.env}_${local.project_name}_k8s_node_sg"
  description = "K8s node secuirty group"
  vpc_id      = data.aws_vpc.main.id 
  tags = {
    Name = "${local.env}_${local.project_name}_k8s_node_sg"
  }
}

# Add rule to allow SSH access (port 22)
resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.sg_main.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
  tags = {
    Name = "allow_ssh_ipv4"
  }
}

# Add rule to allow kube-api access (port 6443)
resource "aws_vpc_security_group_ingress_rule" "allow_6443_ipv4" {
  security_group_id = aws_security_group.sg_main.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 6443
  ip_protocol       = "tcp"
  to_port           = 6443
  tags = {
    Name = "allow_6443_ipv4"
  }
}

# Add rule to allow etcd communication (port 2379)
resource "aws_vpc_security_group_ingress_rule" "allow_2379_ipv4" {
  security_group_id = aws_security_group.sg_main.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 2379
  ip_protocol       = "tcp"
  to_port           = 2379
  tags = {
    Name = "allow_2379_ipv4"
  }
}

# Add rule to allow etcd communication (port 2380)
resource "aws_vpc_security_group_ingress_rule" "allow_2380_ipv4" {
  security_group_id = aws_security_group.sg_main.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 2380
  ip_protocol       = "tcp"
  to_port           = 2380
  tags = {
    Name = "allow_2380_ipv4"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sg_main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
  tags = {
    Name = "allow_all_traffic_ipv4"
  }
}

# IAM