resource "aws_placement_group" "frontend" {
  name     = local.common_resource_name
  strategy = "spread"
}

resource "aws_key_pair" "master" {
  key_name   = "${local.common_resource_name}-master"
  public_key = var.ssh_master_public_key
}

resource "aws_security_group" "services" {
  for_each = var.tuxedo_services

  name   = "${each.key}-${local.common_resource_name}"
  vpc_id = data.aws_vpc.heritage.id

  tags = merge(local.common_tags, {
    Name             = "${each.key}-${local.common_resource_name}"
    TuxedoServerType = each.key
  })
}


resource "aws_vpc_security_group_ingress_rule" "frontend_web_ingress" {
  for_each = local.frontend_web_ingress_rules

  security_group_id = aws_security_group.services[each.value.group].id
  description       = "Allow client requests from frontend web servers to ${upper(each.value.service)} service in ${upper(each.value.group)} server group"
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "backend_ingress" {
  for_each = local.backend_ingress_rules

  security_group_id = aws_security_group.services[each.value.group].id
  description       = "Allow client requests from backend servers or network load balancers to ${upper(each.value.service)} service in ${upper(each.value.group)} server group"
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "chs_ingress" {
  for_each = local.chs_ingress_rules

  security_group_id = aws_security_group.services[each.value.group].id
  description       = "Allow client requests from CHS services to ${upper(each.value.service)} service in ${upper(each.value.group)} server group"
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "ceu_ingress" {
  for_each = local.ceu_ingress_rules

  security_group_id = aws_security_group.services[each.value.group].id
  description       = "Allow client requests from Live CEU frontend to ${upper(each.value.service)} service in ${upper(each.value.group)} server group"
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_security_group" "common" {
  name   = "common-${local.common_resource_name}"
  vpc_id = data.aws_vpc.heritage.id

  tags = merge(local.common_tags, {
    Name = "common-${local.common_resource_name}"
  })
}

resource "aws_vpc_security_group_ingress_rule" "admin_ingress" {
  security_group_id = aws_security_group.common.id
  description       = "Allow SSH connectivity for application deployments"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.shared_services_management.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "chips_ingress" {
  for_each = {
    for rule in local.chips_ingress_rules : "${rule.service}-${rule.port}-${rule.cidr_ipv4}" => rule
  }

  security_group_id = aws_security_group.common.id
  description       = "Allow connectivity from CHIPS to Tuxedo ${upper(each.value.service)} services"
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

# TODO Remove after confirming on-prem frontend connectivity to Tuxedo services no longer required
resource "aws_vpc_security_group_ingress_rule" "on_prem_frontend_ingress_rules" {
  for_each = local.on_prem_frontend_ingress_rules

  security_group_id = aws_security_group.services[each.value.group].id
  description       = "Allow client requests from Live CEU frontend to ${upper(each.value.service)} service in ${upper(each.value.group)} server group"
  cidr_ipv4         = each.value.cidr_ipv4
  from_port         = each.value.port
  to_port           = each.value.port
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all_egress" {
  security_group_id = aws_security_group.common.id
  description       = "Allow all outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_instance" "frontend" {
  count = var.instance_count

  ami             = data.aws_ami.chl_tuxedo.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.master.id
  placement_group = aws_placement_group.frontend.id
  subnet_id       = element(local.application_subnet_ids_by_az, count.index) # use 'element' function for wrap-around behaviour

  iam_instance_profile   = module.instance_profile.aws_iam_instance_profile.name
  user_data_base64       = data.cloudinit_config.config[count.index].rendered
  vpc_security_group_ids = concat([aws_security_group.common.id], [for k, v in aws_security_group.services : v.id])

  dynamic "ebs_block_device" {
    for_each = [
      for block_device in data.aws_ami.chl_tuxedo.block_device_mappings : block_device
      if block_device.device_name != data.aws_ami.chl_tuxedo.root_device_name
    ]
    iterator = block_device
    content {
      device_name = block_device.value.device_name
      encrypted   = block_device.value.ebs.encrypted
      iops        = block_device.value.ebs.iops
      snapshot_id = block_device.value.ebs.snapshot_id
      volume_size = var.lvm_block_devices[index(var.lvm_block_devices[*].lvm_physical_volume_device_node, block_device.value.device_name)].aws_volume_size_gb
      volume_type = block_device.value.ebs.volume_type
    }
  }

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = merge(local.common_tags, {
    Name = "${var.service_subtype}-${var.service}-${var.environment}-${count.index + 1}"
  })
  volume_tags = local.common_tags
}
