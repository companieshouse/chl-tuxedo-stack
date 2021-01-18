provider "aws" {
  alias   = "dns_hosted_zone_account"
  profile = "development-${var.region}"
  region  = var.region
  version = "~> 2.65.0"
}

data "aws_route53_zone" "frontend" {
  name     = var.dns_zone
  provider = aws.dns_hosted_zone_account
}

resource "aws_route53_record" "frontend" {
  provider = aws.dns_hosted_zone_account

  zone_id = data.aws_route53_zone.frontend.zone_id
  name    = "${var.service_subtype}.${var.service}.${var.environment}.${var.dns_zone}"
  type     = "A"

  alias {
    name    = aws_lb.frontend.dns_name
    zone_id = aws_lb.frontend.zone_id

    evaluate_target_health = false
  }
}
