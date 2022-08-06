resource "aws_lb_target_group" "target-group" {
  name     = "${var.COMPONENT}-${var.ENV}"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.VPC_ID

  health_check {
    enabled = true
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 6
    path = "/health"
  }
}

resource "aws_lb_target_group_attachment" "attach" {
  count = var.INSTANCE_COUNT
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_spot_instance_request.instance.*.spot_instance_id[count.index]
  port             = 80
}

resource "aws_lb_listener" "frontend" {
  count             = var.LB_TYPE == "public" ? 1 : 0
  load_balancer_arn = var.LB_ARN
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:041583668323:certificate/7421a91c-7f8f-41ee-8fc4-b190e3f8aad8"
  //get certificate for our domain name fron amazon certificate manager
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target-group.arn
  }
}