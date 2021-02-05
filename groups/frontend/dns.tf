data "aws_route53_zone" "frontend" {
  name     = "${var.environment}.${var.dns_zone_suffix}"
  vpc_id   = data.aws_vpc.heritage.id
}

resource "aws_route53_record" "frontend" {
  zone_id = data.aws_route53_zone.frontend.zone_id
  name    = "${var.service_subtype}.${var.service}.${var.environment}.${var.dns_zone_suffix}"
  type     = "A"

  alias {
    name    = aws_lb.frontend.dns_name
    zone_id = aws_lb.frontend.zone_id

    evaluate_target_health = false
  }
}
