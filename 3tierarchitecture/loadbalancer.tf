resource "aws_lb" "alb_global" {
  name               = "basic-load-balancer"
  load_balancer_type = "application"
  subnets            = "${aws_subnet.public_subnet.*.id}" 
  enable_cross_zone_load_balancing = true
  security_groups = [aws_security_group.lb_sg.id]
  tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-lb"}))}"
  
  tags_all = merge({
    "Name" = "${local.appname}-lb"
  })
}

resource "aws_lb_listener" "alb_listner_443" {
  load_balancer_arn = aws_lb.alb_global.arn

  port              = 443
  protocol          = "HTTPS" 
  ssl_policy        = "ELBSecurityPolicy-2016-08" # very important as it will define tls, cipher etc. check https://docs.aws.amazon.com/elasticloadbalancing/latest/application/create-https-listener.html
  
  certificate_arn   = aws_acm_certificate.test_cloudlearner_crt.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_80_app1.arn
  }

  tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-listen-443"}))}"
  
  tags_all = merge({
    "Name" = "${local.appname}-listen-443"
  })
}

resource "aws_lb_target_group" "alb_target_80_app1" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.AWSVPC.id

  load_balancing_algorithm_type = "least_outstanding_requests"

  stickiness {
    enabled = true
    type    = "lb_cookie"
  }

  health_check {
    healthy_threshold   = 2
    interval            = 30
    protocol            = "HTTP"
    unhealthy_threshold = 2
  }

  # required as no direct linking between lb and target
  depends_on = [
    aws_lb.alb_global
  ]

  lifecycle {
    create_before_destroy = true
  }

  tags = "${merge(local.common_tags,tomap({"Name"="${local.appname}-target-443"}))}"
  
  tags_all = merge({
    "Name" = "${local.appname}-target-443"
  })
}


# Creating Security Group for ELB
resource "aws_security_group" "lb_sg" {
  name        = "LB security group"
 
  vpc_id      = "${aws_vpc.AWSVPC.id}"
# Inbound Rules
 
  # HTTPS access from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
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

