locals {
  application_subnet_ids_by_az = values(zipmap(data.aws_subnet.application.*.availability_zone, data.aws_subnet.application.*.id))

  common_tags = {
    Environment    = var.environment
    Service        = var.service
    ServiceSubType = var.service_subtype
    Team           = "Platform"
  }

  common_resource_name = "${var.service_subtype}-${var.service}-${var.environment}"

  instance_hostname    = "${var.service_subtype}-${var.service}-${var.environment}"

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
