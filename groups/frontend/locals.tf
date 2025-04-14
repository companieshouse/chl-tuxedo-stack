locals {
  application_subnet_ids_by_az = values(zipmap(data.aws_subnet.application[*].availability_zone, data.aws_subnet.application[*].id))

  common_tags = {
    Environment    = var.environment
    Service        = var.service
    ServiceSubType = var.service_subtype
    Team           = var.team
  }

  common_resource_name = "${var.service_subtype}-${var.service}-${var.environment}"
  dns_zone             = "${var.environment}.${var.dns_zone_suffix}"

  security_s3_data            = data.vault_generic_secret.security_s3_buckets.data
  session_manager_bucket_name = local.security_s3_data.session-manager-bucket-name

  security_kms_keys_data = data.vault_generic_secret.security_kms_keys.data
  ssm_kms_key_id         = local.security_kms_keys_data.session-manager-kms-key-arn

  tuxedo_services = flatten([
    for tuxedo_server_type_key, tuxedo_services in var.tuxedo_services : [
      for tuxedo_service_key, tuxedo_service_port in tuxedo_services : {
        tuxedo_server_type_key = tuxedo_server_type_key
        tuxedo_service_key     = tuxedo_service_key
        tuxedo_service_port    = tuxedo_service_port
      }
    ]
  ])

  tuxedo_service_log_groups = merge([
    for tuxedo_service_key, tuxedo_logs_list in var.tuxedo_service_log_groups : {
      for tuxedo_log in setproduct(tuxedo_logs_list, ["stdout", "stderr"]) : "${var.service_subtype}-${var.service}-${tuxedo_service_key}-${lower(tuxedo_log[0].name)}-${tuxedo_log[1]}" => {
        log_retention_in_days = tuxedo_log[0].log_retention_in_days != null ? tuxedo_log[0].log_retention_in_days : var.default_log_retention_in_days
        kms_key_id            = tuxedo_log[0].kms_key_id != null ? tuxedo_log[0].kms_key_id : local.logs_kms_key_id
        tuxedo_service        = tuxedo_service_key
        log_name              = tuxedo_log[0].name
        log_type              = tuxedo_log[1]
      }
    }
  ]...)

  tuxedo_user_log_groups = merge([
    for tuxedo_service_key, tuxedo_user_logs_list in var.tuxedo_user_log_groups : {
      for tuxedo_user_log in tuxedo_user_logs_list : "${var.service_subtype}-${var.service}-${tuxedo_service_key}-${lower(tuxedo_user_log.name)}" => {
        log_retention_in_days = tuxedo_user_log.log_retention_in_days != null ? tuxedo_user_log.log_retention_in_days : var.default_log_retention_in_days
        kms_key_id            = tuxedo_user_log.kms_key_id != null ? tuxedo_user_log.kms_key_id : local.logs_kms_key_id
        tuxedo_service        = tuxedo_service_key
        log_name              = tuxedo_user_log.name
        log_type              = "individual"
      }
    }
  ]...)

  tuxedo_ngsrv_log_groups = merge([
    for tuxedo_service_key, ngsrv_logs_list in var.tuxedo_ngsrv_log_groups : {
      for ngsrv_log in ngsrv_logs_list : "${var.service_subtype}-${var.service}-${tuxedo_service_key}-ngsrv-${lower(ngsrv_log.name)}" => {
        log_retention_in_days = ngsrv_log.log_retention_in_days != null ? ngsrv_log.log_retention_in_days : var.default_log_retention_in_days
        kms_key_id            = ngsrv_log.kms_key_id != null ? ngsrv_log.kms_key_id : local.logs_kms_key_id
        tuxedo_service        = tuxedo_service_key
        log_name              = ngsrv_log.name
      }
    }
  ]...)

  tuxedo_log_groups = merge(
    local.tuxedo_service_log_groups,
    local.tuxedo_user_log_groups
  )

  chips_ingress_rules = flatten([
    for service_name, port_number in var.tuxedo_domains : [
      for cidr_block in data.aws_subnet.application[*].cidr_block : {
        service   = service_name
        port      = port_number
        cidr_ipv4 = cidr_block
      }
    ]
  ])

  all_services = merge([
    for server_group, group_config in var.tuxedo_services : {
      for service_name, port_number in group_config : "${service_name}-${server_group}" => {
        service = service_name
        group   = server_group
        port    = port_number
      }
    }
  ]...)

  lb_health_check_ingress_rules = merge([
    for cidr_block in formatlist("%s/32", [for eni in data.aws_network_interface.nlb : eni.private_ip]) : {
      for service_and_group_name, config in local.all_services : "${service_and_group_name}-${cidr_block}" => merge(config, { cidr_ipv4 = cidr_block })
    }
  ]...)

  frontend_web_ingress_rules = merge([
    for cidr_block in data.aws_subnet.web[*].cidr_block : {
      for service_and_group_name, config in local.all_services : "${service_and_group_name}-${cidr_block}" => merge(config, { cidr_ipv4 = cidr_block })
    }
  ]...)

  backend_ingress_rules = merge([
    for cidr_block in data.aws_subnet.application[*].cidr_block : {
      for service_and_group_name, config in local.all_services : "${service_and_group_name}-${cidr_block}" => merge(config, { cidr_ipv4 = cidr_block })
    }
  ]...)

  on_prem_frontend_ingress_rules = var.environment == "development" ? {} : merge([
    for cidr_block in var.on_premise_frontend_cidrs : {
      for service_and_group_name, config in local.all_services : "${service_and_group_name}-${cidr_block}" => merge(config, { cidr_ipv4 = cidr_block })
    }
  ]...)

  chs_ingress_rules = merge([
    for cidr_block in nonsensitive(local.chs_application_cidrs) : {
      for service_name, port_number in var.tuxedo_services["chs"] : "${service_name}-chs-${cidr_block}" => {
        service   = service_name
        group     = "chs"
        port      = port_number
        cidr_ipv4 = cidr_block
      }
    }
  ]...)

  ceu_ingress_rules = var.environment != "live" ? {} : merge([
    for cidr_block in nonsensitive(local.ceu_live_fe_application_cidrs) : {
      for service_name, port_number in var.tuxedo_services["ceu"] : "${service_name}-ceu-${cidr_block}" => {
        service   = service_name
        group     = "ceu"
        port      = port_number
        cidr_ipv4 = cidr_block
      }
    }
  ]...)

  logs_kms_key_id = data.vault_generic_secret.kms_keys.data["logs"]

  chs_application_cidrs = values(data.vault_generic_secret.chs_application_cidrs.data)

  ceu_live_fe_application_cidrs = var.environment == "live" ? jsondecode(data.vault_generic_secret.ceu_live_fe_outputs[0].data["ceu-frontend-web-subnets-cidrs"]) : []
}
