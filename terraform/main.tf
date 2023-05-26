provider "aws" {
  region = var.region
}

resource "aws_vpc" "app-vpc" {
    cidr_block = var.vpc_cidr_block
    tags = {
        Name = "${var.env_prefix}-vpc"
    }
}

resource "aws_subnet" "app-subnet-1" {
    vpc_id = aws_vpc.app-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name = "${var.env_prefix}-subnet}"
    }
}

output "vpc-id" {
    value = aws_vpc.app-vpc.id
}

output "subnet-id" {
    value = aws_subnet.app-subnet-1.id
}

resource "aws_default_route_table" "app-default-rtb" {
    default_route_table_id = aws_vpc.app-vpc.default_route_table_id
    
    route {
    	cidr_block = "0.0.0.0/0"
    	gateway_id = aws_internet_gateway.app-igw.id
    }
    
    tags = {
    	Name = "${var.env_prefix}-main-rtb"
    }
}

# virtual internet gateway
resource "aws_internet_gateway" "app-igw" {
    vpc_id = aws_vpc.app-vpc.id
    tags = {
    	Name = "${var.env_prefix}-igw"
    }
    
}

# associate a subnet to a routing table
resource "aws_route_table_association" "ass-rtb-subnet" {
    subnet_id = aws_subnet.app-subnet-1.id
    #route_table_id = aws_route_table.app-route-table.id
    route_table_id = aws_default_route_table.app-default-rtb.id
}

# configure security group to ssh your app
## resource "aws_security_group" "app-sg" {
# or define security rules in default sg
resource "aws_default_security_group" "app-default-sg" {
    #name = "app-sg"
    vpc_id = aws_vpc.app-vpc.id
    
    ingress {
    	from_port= 22
    	to_port= 22
    	protocol= "tcp"
    	cidr_blocks = [var.my_ip] 
    }
    
    ingress {
    	from_port= 8080
    	to_port= 8080
    	protocol= "tcp"
    	cidr_blocks = ["0.0.0.0/0"] 
    }
    
    egress {
    	from_port= 0
    	to_port= 0
    	protocol= "-1"
    	cidr_blocks = ["0.0.0.0/0"]
    	prefix_list_ids = []
    }
    
    tags = {
    	Name = "${var.env_prefix}-default-sg"
    }
}

data "aws_ami" "latest-amazon-linux-image" {
    most_recent = true
    owners = ["amazon"]
    filter {
    	name   = "name"
      	values = ["*-ami-*-x86_64"]
    }
    filter {
    	name   = "virtualization-type"
    	values = ["hvm"]
    }
}

output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

## This key-pair is removed because created in ec2
##  and configure in jenkins as a credentials
/*
resource "aws_key_pair" "ssh-key" {
    key_name = "eks-nodes"
    public_key = "${file(var.public_key_location)}"
}
*/

resource "aws_instance" "app-server" {
    ami = data.aws_ami.latest-amazon-linux-image.id
    instance_type = var.instance_type
    
    subnet_id = aws_subnet.app-subnet-1.id
    vpc_security_group_ids = [aws_default_security_group.app-default-sg.id]
    availability_zone = var.avail_zone
    
    associate_public_ip_address = true
    
    # the key_name created in aws.
    key_name = "mayapp-key-pair"
    #key_name = aws_key_pair.ssh-key.key_name
    
    connection {
       	type     = "ssh"
      	user     = "ec2-user"
      	private_key = "${file(var.private_key_location)}"
      	host     = self.public_ip
    }
    
    provisioner "file" {
    	source = "entry-script.sh"
    	destination = "/home/ec2-user/entry-script-on-ec2.sh"
    }
    
    user_data = "${file("entry-script.sh")}"
    
    provisioner "local-exec" {
    	command = "echo ${self.public_ip}"
    }
    
    tags = {
    	Name = "${var.env_prefix}-server"
    }
}

output "ec2_public_ip" {
    value = aws_instance.app-server.public_ip
}
