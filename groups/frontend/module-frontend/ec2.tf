
resource "aws_autoscaling_attachment" "asg_attachment_bar" {
  autoscaling_group_name = aws_autoscaling_group.frontend.id
  elb                    = aws_lb.frontend.id
}

resource "aws_placement_group" "frontend" {
  name     = "${var.service_subtype}-${var.service}-${var.environment}-pg"
  strategy = "spread"
}

locals {
  instance_tags = {
    Name           = "${var.service_subtype}-${var.service}-${var.environment}"
    Environment    = var.environment
    Service        = var.service
    ServiceSubType = var.service_subtype
  }
}

data "null_data_source" "instance_tags" {
  count = length(keys(local.instance_tags))
  inputs = {
    key                 = element(keys(local.instance_tags), count.index)
    value               = element(values(local.instance_tags), count.index)
    propagate_at_launch = "true"
  }
}

resource "aws_autoscaling_group" "frontend" {
  name = "${var.service_subtype}-${var.service}-${var.environment}-asg"

  # TODO introduce variables
  max_size         = 1
  min_size         = 1
  desired_capacity = 1

  # TODO health checks

  launch_configuration = aws_launch_configuration.frontend.name
  placement_group      = aws_placement_group.frontend.id
  vpc_zone_identifier  = var.application_subnets

  lifecycle {
    ignore_changes = [
      load_balancers,
      target_group_arns
    ]
  }

  # TODO user-data for application and config deployment

  tags = data.null_data_source.instance_tags.*.outputs
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

resource "aws_launch_configuration" "frontend" {
  name_prefix     = "${var.service_subtype}-${var.service}-${var.environment}-"
  image_id        = data.aws_ami.chl_tuxedo.id
  instance_type   = var.instance_type
  key_name        = var.ssh_keyname
  security_groups = [aws_security_group.frontend.id]

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

  lifecycle {
    create_before_destroy = true
  }

  # TODO userdata for cloud-init configuration for tux install/configure/startup after new instance creation
  # TODO lifecycle hooks for state change alerts
}

resource "aws_security_group" "frontend" {
  name   = "${var.service_subtype}-${var.service}-${var.environment}-sg"
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

  tags = {
    Name           = "${var.service_subtype}-${var.service}-${var.environment}-sg"
    Environment    = var.environment
    Service        = var.service
    ServiceSubType = var.service_subtype
  }
}
