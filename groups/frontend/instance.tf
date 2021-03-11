data "aws_vpc" "heritage" {
  filter {
    name   = "tag:Name"
    values = ["vpc-heritage-${var.environment}"]
  }
}

data "aws_subnet_ids" "application" {
  vpc_id = data.aws_vpc.heritage.id

  filter {
    name   = "tag:Name"
    values = [var.application_subnet_pattern]
  }
}

data "aws_subnet" "application" {
  count = length(data.aws_subnet_ids.application.ids)
  id    = tolist(data.aws_subnet_ids.application.ids)[count.index]
}

data "aws_subnet_ids" "web" {
  vpc_id = data.aws_vpc.heritage.id

  filter {
    name   = "tag:Name"
    values = [var.web_subnet_pattern]
  }
}

data "aws_subnet" "web" {
  count = length(data.aws_subnet_ids.web.ids)
  id    = tolist(data.aws_subnet_ids.web.ids)[count.index]
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

resource "aws_placement_group" "frontend" {
  name     = local.common_resource_name
  strategy = "spread"
}

resource "aws_key_pair" "master" {
  key_name   = "${local.common_resource_name}-master"
  public_key = var.ssh_master_public_key
}

# Individual security groups for Tuxedo server types (i.e. ceu, chd, ewf, xml)
resource "aws_security_group" "services" {
  for_each = var.tuxedo_services

  name   = "${each.key}-${local.common_resource_name}"
  vpc_id = data.aws_vpc.heritage.id

  dynamic "ingress" {
    for_each = each.value
    iterator = service
    content {
      description = "Allow health check requests from network load balancer to ${service.key} service in ${each.key} server group"
      from_port   = service.value
      to_port     = service.value
      protocol    = "TCP"
      cidr_blocks = formatlist("%s/32", [for eni in data.aws_network_interface.nlb : eni.private_ip])
    }
  }

  dynamic "ingress" {
    for_each = each.value
    iterator = service
    content {
      description = "Allow client requests from frontend web servers to ${service.key} service in ${each.key} server group"
      from_port   = service.value
      to_port     = service.value
      protocol    = "TCP"
      cidr_blocks = data.aws_subnet.web.*.cidr_block
    }
  }

  tags = merge(local.common_tags, {
    Name             = "${each.key}-${local.common_resource_name}"
    TuxedoServerType = each.key
  })
}

# Single security group for common rules
resource "aws_security_group" "common" {
  name   = "common-${local.common_resource_name}"
  vpc_id = data.aws_vpc.heritage.id

  ingress {
    description = "Allow SSH connectivity from trusted subnets"
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.ssh_cidrs
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags ,{
    Name = "common-${local.common_resource_name}"
  })
}

resource "aws_instance" "frontend" {
  count = var.instance_count

  ami             = data.aws_ami.chl_tuxedo.id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.master.id
  placement_group = aws_placement_group.frontend.id
  subnet_id       = element(local.application_subnet_ids_by_az, count.index) # use 'element' function for wrap-around behaviour

  user_data_base64       = data.template_cloudinit_config.config[count.index].rendered
  vpc_security_group_ids = concat([aws_security_group.common.id], [for k, v in aws_security_group.services : v.id])

  dynamic "ebs_block_device" {
    for_each = [
      for block_device in data.aws_ami.chl_tuxedo.block_device_mappings :
        block_device if block_device.device_name != data.aws_ami.chl_tuxedo.root_device_name
    ]
    iterator = block_device
    content {
      device_name = block_device.value.device_name
      encrypted   = block_device.value.ebs.encrypted
      iops        = block_device.value.ebs.iops
      snapshot_id = block_device.value.ebs.snapshot_id
      volume_size = var.lvm_block_devices[index(var.lvm_block_devices.*.lvm_physical_volume_device_node, block_device.value.device_name)].aws_volume_size_gb
      volume_type = block_device.value.ebs.volume_type
    }
  }

  root_block_device {
    volume_size = var.root_volume_size
  }

  tags = merge(local.common_tags ,{
    Name = "i${count.index}.${var.service_subtype}.${var.service}-${var.environment}"
  })
  volume_tags = local.common_tags
}
