resource "aws_lb" "frontend" {
  name               = var.common_resource_name
  internal           = true
  load_balancer_type = "network"
  subnets            = var.lb_subnet_ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = var.lb_deletion_protection

  tags = var.common_tags
}

locals {
  tuxedo_services = flatten([
    for tuxedo_server_type_key, tuxedo_services in var.tuxedo_services : [
      for tuxedo_service_key, tuxedo_service_port in tuxedo_services : {
        tuxedo_server_type_key = tuxedo_server_type_key
        tuxedo_service_key     = tuxedo_service_key
        tuxedo_service_port    = tuxedo_service_port
      }
    ]
  ])
}

resource "aws_lb_listener" "frontend" {
  for_each = {
    for service in local.tuxedo_services : "${service.tuxedo_service_key}.${service.tuxedo_server_type_key}" => service
  }

  load_balancer_arn = aws_lb.frontend.arn
  port              = each.value.tuxedo_service_port
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend[each.key].arn
  }
}

resource "aws_lb_target_group" "frontend" {
  for_each = {
    for service in local.tuxedo_services : "${service.tuxedo_service_key}.${service.tuxedo_server_type_key}" => service
  }

  name        = var.common_resource_name
  vpc_id      = var.vpc_id
  port        = each.value.tuxedo_service_port
  protocol    = "TCP"
  target_type = "instance"
  # deregistration_delay = 10

  # Defaults to port 'traffic-port' and type 'TCP' meaning same port as LB
  health_check {
    interval            = "30"
    # port                = "80"  use default of 'traffic-port'
    # protocol = "TCP" this is default so no need to specify
    healthy_threshold   = "3"
    unhealthy_threshold = "3"
    timeout             = "5"
  }

  tags = merge(var.common_tags, {
    TuxedoServerType = "${each.value.tuxedo_server_type_key}",
    TuxedoService    = "${each.value.tuxedo_service_key}",
  })
}

resource "aws_lb_target_group_attachment" "frontend" {
  for_each = {
    for pair in setproduct(local.tuxedo_services, range(length(aws_instance.frontend))) :
    "${pair[0].tuxedo_service_key}.${pair[0].tuxedo_server_type_key}.${pair[1]}" => {
      instance_index     = pair[1]
      tuxedo_service_key = "${pair[0].tuxedo_service_key}.${pair[0].tuxedo_server_type_key}"
    }
  }

  target_group_arn = aws_lb_target_group.frontend[each.value.tuxedo_service_key].arn
  target_id        = aws_instance.frontend[each.value.instance_index].arn
}
