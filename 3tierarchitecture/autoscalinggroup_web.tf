resource "tls_private_key" "web_private_key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "web_key_pair" {
  key_name   = "terraform-provider-aws-issue-clear-key-name"
  public_key = tls_private_key.web_private_key.public_key_openssh
}

resource "local_file" "private_key" {
  depends_on = [
    tls_private_key.web_private_key,
  ]
  content  = tls_private_key.web_private_key.private_key_pem
  filename = "webapp.pem"
}

# Creating Security Group for autp scaling group web
resource "aws_security_group" "web_asg_sg" {
  name        = "web auto scaling group security group"
  vpc_id      = "${aws_vpc.AWSVPC.id}"
# Inbound Rules
  # HTTPS access from anywhere
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

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_launch_configuration" "web" {
  name_prefix = "web-"
  image_id = "ami-0ba7ce450750cc725" 
  instance_type = "t2.micro"
  key_name = aws_key_pair.web_key_pair.key_name
  security_groups = [aws_security_group.web_asg_sg.id]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name = "${aws_launch_configuration.web.name}-asg"
  min_size             = 2
  desired_capacity     = 2
  max_size             = 3
  health_check_type    = "ELB"
  target_group_arns = ["${aws_lb_target_group.alb_target_80_app1.arn}"]
  launch_configuration = "${aws_launch_configuration.web.name}"
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]
  metrics_granularity = "1Minute"
  vpc_zone_identifier  = [aws_subnet.private_subnet[0].id,aws_subnet.private_subnet[1].id]
# Required to redeploy without an outage.
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
  
  depends_on = [
    aws_lb.alb_global
  ]
}
