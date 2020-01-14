provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}
#-----IAM----------------------

#s3cess

resource "aws_iam_instance_profile" "s3_access_profile" {
  name = "s3_access"
  role = "${aws_iam_role.s3_access_role.name}"
}

resource "aws_iam_role_policy" "s3_access_policy" {
  name = "s3_access_policy"
  role = "${aws_iam_role.s3_access_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role" "s3_access_role" {
  name               = "s3_access_role"
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
  {
    "Action": "sts:AssumeRole",
    "Principal": {
        "Service": "ec2.amazonaws.com"
     },
    "Effect": "Allow",
    "Sid": ""
  }
]
}
EOF
}

#-------VPC------------------------


resource "aws_vpc" "wp_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "wp_vpc"
  }
}
#-------IGW-----------------------------

resource "aws_internet_gateway" "wp_igw" {
  vpc_id = "${aws_vpc.wp_vpc.id}"

  tags = {
    Name = "wp_igw"
  }
}

#--------NAT Gateway--------------
#eip
resource "aws_eip" "wp_eip" {
vpc      = true
}
resource "aws_nat_gateway" "wp_nat"{
  allocation_id = "${aws_eip.wp_eip.id}"
  subnet_id = "${aws_subnet.wp_public1.id}"
  depends_on = ["aws_internet_gateway.wp_igw"]
}

#------Route tables------------------

resource "aws_route_table" "wp_public_rt" {
  vpc_id = "${aws_vpc.wp_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.wp_igw.id}"
  }
  tags = {
    Name = "wp_public_rt"
  }
}

resource "aws_route_table" "wp_private_rt" {
 vpc_id = "${aws_vpc.wp_vpc.id}"
 route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id  = "${aws_nat_gateway.wp_nat.id}"
 }
 tags = {
    Name = "wp_private"
 }
}

#------Subnets----------------------

resource "aws_subnet" "wp_public1" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "wp_public1"
  }
}

resource "aws_subnet" "wp_public2" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["public2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  tags = {
    Name = "wp_public2"
  }
}

resource "aws_subnet" "wp_private1" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["private1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "wp_private1"
  }
}

resource "aws_subnet" "wp_private2" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["private2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  tags = {
    Name = "wp_priavte2"
  }
}


resource "aws_subnet" "wp_rds1" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"
  tags = {
    Name = "wp_rds1"
  }
}

resource "aws_subnet" "wp_rds2" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"
  tags = {
    Name = "wp_rds2"
  }
}

resource "aws_subnet" "wp_rds3" {
  vpc_id                  = "${aws_vpc.wp_vpc.id}"
  cidr_block              = "${var.cidrs["rds3"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[2]}"
  tags = {
    Name = "wp_rds3"
  }
}

#-------Subnetgroup for RDS --------------

resource "aws_db_subnet_group" "wp_rds_subnetgroup" {
  name       = "wp_rds_sunetgroup"
  subnet_ids = ["${aws_subnet.wp_rds1.id}", "${aws_subnet.wp_rds2.id}", "${aws_subnet.wp_rds3.id}"]
  tags = {
    Name = "wp_rds_subnetgroup"
  }

}

#--------Subnet-Association-in-Routetable---------

resource "aws_route_table_association" "wp_public1_association" {
  subnet_id      = "${aws_subnet.wp_public1.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_public2_association" {
  subnet_id      = "${aws_subnet.wp_public2.id}"
  route_table_id = "${aws_route_table.wp_public_rt.id}"
}

resource "aws_route_table_association" "wp_private1_association" {
  subnet_id      = "${aws_subnet.wp_private1.id}"
  route_table_id = "${aws_route_table.wp_private_rt.id}"
}

resource "aws_route_table_association" "wp_private2_association" {
  subnet_id      = "${aws_subnet.wp_private2.id}"
  route_table_id = "${aws_route_table.wp_private_rt.id}"
}

#------Security-Groups------------------------
resource "aws_security_group" "wp_dev_sg" {
  name        = "wp_dev_sg"
  description = "Used for access to dev instance bastion host"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  #ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}"]
  }
  #http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${var.localip}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#public-security-group
resource "aws_security_group" "wp_public_sg" {
  name        = "wp_public_sg"
  description = "Used for ELB for public access"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  #http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#private-security-group
resource "aws_security_group" "wp_private_sg" {
  name        = "wp_private_sg"
  description = "Used for private instances"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  #Access from VPC
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["${var.vpc_cidr}"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#RDS-security-group
resource "aws_security_group" "wp_rds_sg" {
  name        = "wp_rds_sg"
  description = "Used for RDS instances"
  vpc_id      = "${aws_vpc.wp_vpc.id}"

  #SQL access  from public/private security groups
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = ["${aws_security_group.wp_dev_sg.id}", "${aws_security_group.wp_public_sg.id}", "${aws_security_group.wp_private_sg.id}"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#------s3bucket------------------------

#vpcendpoint-for-s3

resource "aws_vpc_endpoint" "wp_private_s3_endpoint" {
  vpc_id       = "${aws_vpc.wp_vpc.id}"
  service_name = "com.amazonaws.${var.aws_region}.s3"

  route_table_ids = ["${aws_vpc.wp_vpc.main_route_table_id}", "${aws_route_table.wp_public_rt.id}"]
  policy          = <<POLICY
  {
    "Statement": [
       {
         "Action": "*",
         "Effect": "Allow",
         "Resource": "*",
         "Principal": "*"
       }
     ]
  } 
POLICY
}

#code-s3bucket

resource "random_id" "wp_code_bucket" {
  byte_length = 2
}

resource "aws_s3_bucket" "code" {
  bucket        = "${var.domain_name}-${random_id.wp_code_bucket.dec}"
  acl           = "private"
  force_destroy = true
  tags = {
    Name = "wp_code_bucket"
  }
}

#--------------RDS-----------------------------
resource "aws_db_instance" "wp_db" {
  allocated_storage      = 10
  engine                 = "mysql"
  engine_version         = "5.7.22"
  instance_class         = "${var.db_instance_class}"
  name                   = "${var.dbname}"
  username               = "${var.dbuser}"
  password               = "${var.dbpassword}"
  db_subnet_group_name   = "${aws_db_subnet_group.wp_rds_subnetgroup.name}"
  vpc_security_group_ids = ["${aws_security_group.wp_rds_sg.id}"]
  skip_final_snapshot    = true
}


#-----------DEV-Server------------------
#key-pair
resource "aws_key_pair" "wp_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#dev-server
resource "aws_instance" "wp_dev" {
  instance_type = "${var.dev_instance_type}"
  ami           = "${var.dev_ami}"
  tags = {
    Name = "wp_dev"
  }
  key_name               = "${aws_key_pair.wp_auth.id}"
  vpc_security_group_ids = ["${aws_security_group.wp_dev_sg.id}"]
  iam_instance_profile   = "${aws_iam_instance_profile.s3_access_profile.id}"
  subnet_id              = "${aws_subnet.wp_public1.id}"
  user_data              = "${file("userdata")}"
}


#-------Load-Balancer--------------------

resource "aws_elb" "wp_elb" {
  name = "${var.domain_name}-elb"
  #public subnets 
  subnets         = ["${aws_subnet.wp_public1.id}", "${aws_subnet.wp_public2.id}"]
  security_groups = ["${aws_security_group.wp_public_sg.id}"]
  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }
  health_check {
    healthy_threshold   = "${var.elb_healthy_threshold}"
    unhealthy_threshold = "${var.elb_unhealthy_threshold}"
    timeout             = "${var.elb_timeout}"
    target              = "TCP:80"
    interval            = "${var.elb_interval}"
  }
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}
#Launch-configuration
resource "aws_launch_configuration" "wp_lc" {
  name_prefix          = "wp_lc-"
  image_id             = "${var.dev_ami}"
  instance_type        = "${var.lc_instance_type}"
  security_groups      = ["${aws_security_group.wp_private_sg.id}"]
  iam_instance_profile = "${aws_iam_instance_profile.s3_access_profile.id}"
  key_name             = "${aws_key_pair.wp_auth.id}"
  user_data            = "${file("userdata")}"
  lifecycle {
    create_before_destroy = true
  }
}

#ASG
resource "aws_autoscaling_group" "wp_asg" {
  name                      = "asg-${aws_launch_configuration.wp_lc.id}"
  max_size                  = "${var.max_size}"
  min_size                  = "${var.min_size}"
  health_check_grace_period = "${var.grace}"
  health_check_type         = "${var.hct}"
  desired_capacity          = "${var.desired_cap}"
  force_delete              = true
  load_balancers            = ["${aws_elb.wp_elb.id}"]
  vpc_zone_identifier       = ["${aws_subnet.wp_private1.id}", "${aws_subnet.wp_private2.id}"]
  launch_configuration      = "${aws_launch_configuration.wp_lc.name}"
  tag {
    key                 = "Name"
    value               = "wp_asg-instance"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

