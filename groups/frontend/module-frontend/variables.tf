variable "ami_version_pattern" {
  type        = string
  description = "The pattern to match AMI version to"
}

variable "application_subnets" {
  type        = list(string)
  description = "The application subnets in which to create resources"
}

variable "common_resource_name" {
  type        = string
  description = "A string defining the common resource name to be applied to all applicable resources"
}

variable "common_tags" {
  type        = map(string)
  description = "A map of common tags to associate with resources"
}

variable "dns_zone" {
  type        = string
  description = "The DNS zone used when creating records"
  default     = "aws.chdev.org"
}

variable "environment" {
  type        = string
  description = "The environment name to be used when creating AWS resources"
}

variable "instance_count" {
  type        = number
  description = "The number of instances to create"
}

variable "instance_hostname" {
  type        = string
  description = "The hostname to set for the instance"
}

variable "instance_type" {
  type        = string
  description = "The instance type to use"
}

variable "internal_access_cidrs" {
  type        = list(string)
  description = "A list of subnet CIDR ranges to grant access to the Tuxedo applications via the load balancer"
}

variable "lb_deletion_protection" {
  type        = bool
  description = "A boolean value representing whether to enable load balancer deletion protection"
}

variable "lb_subnet_ids" {
  type        = list(string)
  description = "A list of subnet IDs in which the internal load balancers will be made available"
}

variable "lb_subnet_cidrs" {
  type        = list(string)
  description = "A list of subnet CIDR ranges in which the load balancers will be made available"
}

variable "lvm_block_devices" {
  type = list(object({
    aws_volume_size_gb: string,
    filesystem_resize_tool: string,
    lvm_logical_volume_device_node: string,
    lvm_physical_volume_device_node: string,
  }))
  description = "A list of objects representing LVM block devices; each LVM volume group is assumed to contain a single physical volume and each logical volume is assumed to belong to a single volume group; the filesystem for each logical volume will be expanded to use all available space within the volume group using the filesystem resize tool specified; block device configuration applies only on resource creation. Set the 'filesystem_resize_tool' and 'lvm_logical_volume_device_node' fields to empty strings if the block device contains no filesystem and should be excluded from the automatic filesystem resizing, such as when the block device represents a swap volume"
}

variable "region" {
  type        = string
  description = "The AWS region in which resources will be administered"
}

variable "service" {
  type        = string
  description = "The service name to be used when creating AWS resources"
}

variable "service_subtype" {
  type        = string
  description = "The service subtype name to be used when creating AWS resources"
}

variable "ssh_cidrs" {
  type        = list(string)
  description = "A list of CIDR blocks to permit remote SSH access from"
}

variable "ssh_keyname" {
  type        = string
  description = "The SSH keypair name to use for remote connectivity"
}

variable "tuxedo_services" {
  type        = map(map(number))
  description = "A map whose keys represent server-side tuxedo server groups with nested maps representing individual services by name key and port number value"
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID in which to create resources"
}
