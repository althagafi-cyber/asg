terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  version = ">= 2.17"
  region  = "us-east-1"
}

data "aws_availability_zones" "all" {}

resource "aws_security_group" "sg-althagafi-asg" {
  name = "terraform-asg-instance"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_configuration" "althagafi_lc" {
  name = "althagafi-lc"
  image_id        = "ami-0f90a34c9df977efb"
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.sg-althagafi-asg.id]
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              service httpd start
              chkconfig httpd on
              echo "Hello, World" > index.html
              EOF
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "althagafi_asg" {
  launch_configuration  = aws_launch_configuration.althagafi_lc.id
  availability_zones    = data.aws_availability_zones.all.names
  desired_capacity      = 2
  min_size              = 2
  max_size              = 5
  health_check_type     = "EC2"
    tag {
    key                 = "Name"
    value               = "terraform-asg-althagafi"
    propagate_at_launch = true
  }
}
