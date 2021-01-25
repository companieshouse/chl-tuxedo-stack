resource "aws_placement_group" "frontend" {
  name     = var.common_resource_name
  strategy = "spread"
}

data "aws_ami" "chl_tuxedo" {
  owners      = ["self"]
  most_recent = true
  name_regex  = "^chl-tuxedo-ami-\\d.\\d.\\d"

  filter {
    name   = "name"
    values = ["chl-tuxedo-ami-${var.ami_version_pattern}"]
  }
}

resource "aws_instance" "frontend" {
  count           = var.instance_count

  ami             = data.aws_ami.chl_tuxedo.id
  instance_type   = var.instance_type
  key_name        = var.ssh_keyname
  security_groups = [aws_security_group.frontend.id]
  placement_group = aws_placement_group.frontend.id

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

  tags        = var.common_tags
  volume_tags = var.common_tags
}

resource "aws_security_group" "frontend" {
  name   = var.common_resource_name
  vpc_id = var.vpc_id

  # TODO inbound traffic to applications from ELB

  ingress {
    description = "Inbound SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidrs
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.common_tags
}
