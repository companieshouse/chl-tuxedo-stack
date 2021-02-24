variable "user_data_merge_strategy" {
  default     = "list(append)+dict(recurse_array)+str()"
  description = "Merge strategy to apply to user-data sections for cloud-init"
}

data "template_cloudinit_config" "config" {
  count = var.instance_count

  gzip          = true
  base64_encode = true

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/templates/system-config.yml.tpl", {})
  }

  part {
    content_type = "text/cloud-config"
    content = templatefile("${path.module}/cloud-init/templates/bootstrap-commands.yml.tpl", {
      instance_hostname = "${local.common_resource_name}-${count.index}"
      lvm_block_devices = var.lvm_block_devices
    })
  }
}
