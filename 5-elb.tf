# Create a load balancer target group
resource "aws_lb_target_group" "target_group_main" {
  name     = "k3s-tg"
  port     = 6443
  protocol = "TCP"
  vpc_id   = data.aws_vpc.main.id
  tags = {
    Name = "${local.project_name}_tg"
  }
}

# Attach instaces to target group
resource "aws_lb_target_group_attachment" "target_group_attachment" {
  count = local.node_count
  target_group_arn = aws_lb_target_group.target_group_main.arn
  target_id        = aws_instance.k8s_node[count.index].id
  port             = 6443
}

# Create a application load balancer
resource "aws_lb" "nlb_main" {
  name               = "k3s-nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.sg_main.id]
  subnets            = [data.aws_subnet.subnet_1.id,data.aws_subnet.subnet_2.id]

  tags = {
    Name = "${local.project_name}_nlb"
  }
}

output "nlb_address" {
  value = aws_lb.nlb_main.dns_name
}

# Add listener to load balancer
resource "aws_lb_listener" "anb_listener_main" {
  load_balancer_arn = aws_lb.nlb_main.arn
  port              = "6443"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_main.arn
  }
}