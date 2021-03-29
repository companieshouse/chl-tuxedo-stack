locals {
  application_subnet_ids_by_az = values(zipmap(data.aws_subnet.application.*.availability_zone, data.aws_subnet.application.*.id))

  common_tags = {
    Environment    = var.environment
    Service        = var.service
    ServiceSubType = var.service_subtype
    Team           = var.team
  }

  common_resource_name = "${var.service_subtype}-${var.service}-${var.environment}"
  dns_zone = "${var.environment}.${var.dns_zone_suffix}"

  tuxedo_services = flatten([
    for tuxedo_server_type_key, tuxedo_services in var.tuxedo_services : [
      for tuxedo_service_key, tuxedo_service_port in tuxedo_services : {
        tuxedo_server_type_key = tuxedo_server_type_key
        tuxedo_service_key     = tuxedo_service_key
        tuxedo_service_port    = tuxedo_service_port
      }
    ]
  ])

  tuxedo_log_groups = merge([
    for tuxedo_service_key, tuxedo_logs_list in var.tuxedo_logs : {
      for tuxedo_log in setproduct(tuxedo_logs_list[*].name, ["stdout", "stderr"]) : "${var.service_subtype}-${var.service}-${tuxedo_service_key}-${lower(tuxedo_log[0])}-${tuxedo_log[1]}" => {
        log_retention_in_days = lookup(tuxedo_logs_list[index(tuxedo_logs_list.*.name, tuxedo_log[0])], "log_retention_in_days", var.default_log_retention_in_days)
        kms_key_id = lookup(tuxedo_logs_list[index(tuxedo_logs_list.*.name, tuxedo_log[0])], "kms_key_id", local.logs_kms_key_id)
        tuxedo_service = tuxedo_service_key
        log_name = tuxedo_log[0]
        log_type = tuxedo_log[1]
      }
    }
  ]...)

  logs_kms_key_id = data.vault_generic_secret.kms_keys.data["logs"]
}
