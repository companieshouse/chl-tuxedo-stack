resource "aws_lb" "frontend" {
  name               = "${var.service_subtype}-${var.service}-${var.environment}-lb"
  internal           = true
  load_balancer_type = "network"
  subnets            = var.lb_subnet_ids

  enable_cross_zone_load_balancing = true

  tags = {
    Name           = "${var.service_subtype}-${var.service}-${var.environment}-lb"
    Environment    = var.environment
    Service        = var.service
    ServiceSubType = var.service_subtype
  }
}
