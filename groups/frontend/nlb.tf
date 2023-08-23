data "aws_network_interface" "nlb" {
  for_each = data.aws_subnet_ids.application.ids

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.frontend.arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [each.value]
  }
}

resource "aws_lb" "frontend" {
  name               = local.common_resource_name
  internal           = true
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.application.ids

  enable_cross_zone_load_balancing = true
  enable_deletion_protection       = var.lb_deletion_protection

  tags = merge(local.common_tags, {
    Name = local.common_resource_name
  })
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
    for service in local.tuxedo_services : "${replace(service.tuxedo_service_key, "/sandpit/", "sp")}.${service.tuxedo_server_type_key}" => service
  }

  name        = "${each.value.tuxedo_service_key}-${each.value.tuxedo_server_type_key}-${var.service}-${var.environment}"
  port        = each.value.tuxedo_service_port
  protocol    = "TCP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.heritage.id

  health_check {
    interval            = "30"
    protocol            = "TCP"
    healthy_threshold   = "3"
    unhealthy_threshold = "3"
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name             = "${each.value.tuxedo_service_key}-${each.value.tuxedo_server_type_key}-${var.service}-${var.environment}"
    TuxedoServerType = each.value.tuxedo_server_type_key,
    TuxedoClientType = each.value.tuxedo_service_key,
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

  target_id        = aws_instance.frontend[each.value.instance_index].id
  target_group_arn = aws_lb_target_group.frontend[each.value.tuxedo_service_key].arn
}
