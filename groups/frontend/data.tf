data "aws_caller_identity" "current" {}

data "aws_ec2_managed_prefix_list" "shared_services_management" {
  name = "shared-services-management-cidrs"
}

data "aws_route53_zone" "frontend" {
  name   = local.dns_zone
  vpc_id = data.aws_vpc.heritage.id
}

data "aws_vpc" "heritage" {
  filter {
    name   = "tag:Name"
    values = ["vpc-heritage-${var.environment}"]
  }
}

data "aws_subnets" "application" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.heritage.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.application_subnet_pattern]
  }
}

data "aws_subnet" "application" {
  count = length(data.aws_subnets.application.ids)
  id    = tolist(data.aws_subnets.application.ids)[count.index]
}

data "aws_subnets" "web" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.heritage.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.web_subnet_pattern]
  }
}

data "aws_subnet" "web" {
  count = length(data.aws_subnets.web.ids)
  id    = tolist(data.aws_subnets.web.ids)[count.index]
}

data "aws_ami" "chl_tuxedo" {
  owners      = [var.ami_owner_id]
  most_recent = true
  name_regex  = "^chl-tuxedo-ami-\\d.\\d.\\d"

  filter {
    name   = "name"
    values = ["chl-tuxedo-ami-${var.ami_version_pattern}"]
  }
}

data "cloudinit_config" "config" {
  count = var.instance_count

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/cloud-init/templates/system-config.yml.tpl", {})
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/templates/tnsnames.ora.tpl", {
      tnsnames = jsondecode(data.vault_generic_secret.tns_names.data.tnsnames)
    })
    merge_type = var.user_data_merge_strategy
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/templates/bootstrap-commands.yml.tpl", {
      instance_hostname = "${var.service_subtype}-${var.service}-${var.environment}-${count.index + 1}"
      lvm_block_devices = var.lvm_block_devices
    })
  }
}

data "aws_network_interface" "nlb" {
  for_each = toset(data.aws_subnets.application.ids)

  filter {
    name   = "description"
    values = ["ELB ${aws_lb.frontend.arn_suffix}"]
  }

  filter {
    name   = "subnet-id"
    values = [each.value]
  }
}

data "vault_generic_secret" "kms_keys" {
  path = "aws-accounts/${var.aws_account}/kms"
}

data "vault_generic_secret" "security_s3_buckets" {
  path = "aws-accounts/security/s3"
}

data "vault_generic_secret" "security_kms_keys" {
  path = "aws-accounts/security/kms"
}

data "vault_generic_secret" "tns_names" {
  path = "applications/${var.aws_account}-${var.region}/chl-tuxedo/tnsnames"
}

data "vault_generic_secret" "chs_application_cidrs" {
  path = "aws-accounts/network/${var.aws_account}/chs/application-subnets"
}

data "vault_generic_secret" "ceu_live_fe_outputs" {
  count = var.environment == "live" ? 1 : 0
  path  = "applications/pci-services-${var.region}/ceu/ceu-fe-outputs"
}
