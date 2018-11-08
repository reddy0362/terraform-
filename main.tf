#########################################VPC##################
resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_support = true 
  enable_dns_hostnames = true 
  tags {
    Name = "Vpc"
  }
}
########################################PUBLIC SUBNET ##########

resource "aws_subnet" "PubSub1" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.1.0/24"

  tags {
    Name = "PublicSubnet1"
  }
}
#######################################PRIVATE SUBNET ##########

resource "aws_subnet" "PriSub1" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.3.0/24"

  tags {
    Name = "PrivateSubnet1"
  }
}

########################################ADDING DATABASE#######

resource "aws_db_instance" "db"
  allocated storage=  
  storage          =
  engine           = 
  engine_version   =
  instance_class   = 
  name             = 
  username         = 
  password         = 
  parameter_group_name = 
#######################################EBS VOLUME #################

resource "aws_ebs_volume" "vol" {
    availability_zone = "${aws_subnet.PriSub1.availability_zone}"
    size = "${var.EbsVolume}"

    tags {
        Name = "EbsVolume"
    }
}

##############################################SECURITY GROUP#########
resource "aws_security_group" "sg" {
  vpc_id = "${aws_vpc.vpc.id}"
  name        = "allow_all"
  description = "Allow all inbound traffic"

  ingress {

    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

  ingress {

    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}
  ingress {

    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
}


  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "SecurityGroup"
  }
}
###############################################
# Define the security group for private subnet

resource "aws_security_group" "sgdb" {
  vpc_id = "${aws_vpc.vpc.id}"
  name = "sg_test_web"
  description = "Allow traffic from public subnet"
  ingress {
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port = -1
    to_port = -1
    protocol = "icmp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  tags {
    Name = "Private SG"
  }
}
########################################################################
resource "aws_network_acl" "main" {
  vpc_id ="${aws_vpc.vpc.id}"
  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.3.0.0/18"
    from_port  = 80
    to_port    = 80
  }

  tags {
    Name = "main"
  }
}

################################INTERNET GATEWAY ########################
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "INTERNET GATEWAY"
  }
}
#################################adding a route to internet gateway ############
resource "aws_route" "pub_route" {
  route_table_id   = "${aws_vpc.vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id  = "${aws_internet_gateway.ig.id}"
}
##############################ADDING A ELASTIC IP ########################
resource "aws_eip" "eip" {
  vpc = true 
  depends_on = ["aws_internet_gateway.ig"]
}
###############################CREATING A NAT GATEWAY FOR SUBNET ########
resource "aws_nat_gateway" "nat" {
  allocation_id ="${aws_eip.eip.id}"
  subnet_id = "${ aws_subnet.PubSub1.id }"
  depends_on = ["aws_internet_gateway.ig"]
}
################################CREATING A PriSub1 ROUTE TABLE#############
resource "aws_route_table" "private_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
  
  tags {
    Name = "private subnet route table"
  }
}
###################################adding Prisub1 route to NAT###################
resource "aws_route" "private_route" {
  route_table_id = "${aws_route_table.private_route_table.id}"
  destination_cidr_block = "10.3.0.0/18"
  nat_gateway_id   = "${aws_nat_gateway.nat.id}"
}
##################################Associate a Route table to public###############
resource "aws_route_table_association" "public_association" {
  subnet_id = "${aws_subnet.PubSub1.id}"
  route_table_id = "${aws_vpc.vpc.main_route_table_id}"
}
#####################################Associate Route to private##########
resource "aws_route_table_association" "private_association" {
  subnet_id = "${aws_subnet.PriSub1.id}"
  route_table_id = "${aws_route_table.private_route_table.id}"
}
  
############################################################################
resource "aws_instance" "instance" {
  ami           = "ami-03291866"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.PriSub1.id}"
  key_name = "${var.KeyPairName}"
  security_groups = ["${aws_security_group.sgdb.id}"]
  associate_public_ip_address = false 
  root_block_device {
        volume_size = "${var.RootVolume}"
  }
  ebs_block_device {
        volume_size = "${var.EbsVolume}"
#        volume_size = "${aws_ebs_volume.vol.id}"
        device_name = "/dev/xvda"
  }
  tags {
    Name = "private"
  }
}
##############################################################################

resource "aws_instance" "instance22" {
  ami           = "ami-03291866"
  instance_type = "t2.micro"
  subnet_id = "${aws_subnet.PubSub1.id}"
  key_name = "${var.KeyPairName}"
  security_groups = ["${aws_security_group.sg.id}"]
  associate_public_ip_address = true
  root_block_device {
        volume_size = "${var.RootVolume}"
  }
  ebs_block_device {
        volume_size = "${var.EbsVolume}"
#        volume_size = "${aws_ebs_volume.vol.id}"
        device_name = "/dev/xvda"
  }
  tags {
    Name = "Public"
  }
}

