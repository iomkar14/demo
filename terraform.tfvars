aws_profile = "admin"
aws_region  = "us-east-1"
vpc_cidr    = "10.10.0.0/16"
cidrs = {
  public1  = "10.10.1.0/24"
  public2  = "10.10.2.0/24"
  private1 = "10.10.3.0/24"
  private2 = "10.10.4.0/24"
  rds1     = "10.10.5.0/24"
  rds2     = "10.10.6.0/24"
  rds3     = "10.10.7.0/24"
}
localip = "15.206.93.141/32"

domain_name = "wp-demo"

db_instance_class = "db.t2.micro"
dbname            = "wpdemo"
dbuser            = "admin"
dbpassword        = "admin#1234"

dev_instance_type = "t2.micro"
dev_ami           = "ami-00068cd7555f543d5"
public_key_path   = "/root/.ssh/demo.pub"
key_name          = "demo"

elb_healthy_threshold   = "2"
elb_unhealthy_threshold = "2"
elb_timeout             = "3"
elb_interval            = "30"


lc_instance_type = "t2.micro"
max_size         = "2"
min_size         = "1"
desired_cap      = "2"
grace            = "300"
hct              = "EC2"

