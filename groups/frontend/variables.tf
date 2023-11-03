variable "ami_owner_id" {
  type        = string
  description = "The AMI owner ID."
}

variable "ami_version_pattern" {
  type        = string
  description = "The pattern to use when filtering for AMI version by name."
  default     = "*"
}

variable "application_subnet_pattern" {
  type        = string
  description = "The pattern to use when filtering for application subnets by 'Name' tag."
  default     = "sub-application-*"
}

variable "aws_account" {
  type        = string
  description = "The name of the AWS account in which resources will be provisioned."
}

variable "chips_cidr" {
  type        = string
  description = "A string representing the IPv4 CIDR address from which CHIPS instances will connect to Tuxedo services."
}

variable "default_log_retention_in_days" {
  type        = number
  description = "The default log retention period in days to be used for CloudWatch log groups."
  default     = 7
}

variable "deployment_cidrs" {
  type        = list(string)
  description = "A list of strings representing IPv4 CIDR addresses from which applications will be deployed to Tuxedo instances via Ansible."
}

variable "dns_zone_suffix" {
  type        = string
  description = "The common DNS hosted zone suffix used across accounts."
  default     = "heritage.aws.internal"
}

variable "environment" {
  type        = string
  description = "The environment name to be used when provisioning AWS resources."
}

variable "instance_count" {
  type        = number
  description = "The number EC2 instances to create."
  default     = 1
}

variable "instance_type" {
  type        = string
  description = "The instance type to use for EC2 instances."
  default     = "t3.small"
}

variable "lb_deletion_protection" {
  type        = bool
  description = "A boolean value representing whether to enable load balancer deletion protection"
  default     = false
}

variable "lvm_block_devices" {
  type = list(object({
    aws_volume_size_gb              = string
    filesystem_resize_tool          = string
    lvm_logical_volume_device_node  = string
    lvm_physical_volume_device_node = string
  }))
  description = "A list of objects representing LVM block devices; each LVM volume group is assumed to contain a single physical volume and each logical volume is assumed to belong to a single volume group; the filesystem for each logical volume will be expanded to use all available space within the volume group using the filesystem resize tool specified; block device configuration applies only on resource creation. Set the 'filesystem_resize_tool' and 'lvm_logical_volume_device_node' fields to empty strings if the block device contains no filesystem and should be excluded from the automatic filesystem resizing, such as when the block device represents a swap volume."
  default     = []
}

# TODO Remove this; this was added for testing Tuxedo services in live using on-premise frontend services
variable "on_premise_frontend_cidrs" {
  type        = list(string)
  description = "A list of strings representing the CIDR ranges for on-premise frontend services"
  default     = []
}

variable "region" {
  type        = string
  description = "The AWS region in which resources will be created."
}

variable "root_volume_size" {
  type        = number
  description = "The size of the root volume in gibibytes (GiB)."
  default     = 20
}

variable "service" {
  type        = string
  description = "The service name to be used when creating AWS resources."
  default     = "tuxedo"
}

variable "service_subtype" {
  type        = string
  description = "The service subtype name to be used when creating AWS resources."
  default     = "frontend"
}

variable "ssh_master_public_key" {
  type        = string
  description = "The SSH master public key; EC2 instance connect should be used for regular connectivity."
}

variable "tuxedo_ngsrv_log_groups" {
  type = map(list(
    object({
      name                  = string
      log_retention_in_days = optional(number)
      kms_key_id            = optional(string)
    })
  ))
  description = "A map of lists whose keys represent Tuxedo service groups. Each list object represents a single CloudWatch log group for an nGsrv log and is expected to specify at least a 'name' attribute. Optional 'log_retention_in_days' and 'kms_key_id' attributes can be used to override the default values ('log_retention_in_days' defaults to the value of the 'default_log_retention_in_days' variable, and 'kms_key_id' defaults to a KMS key identifier value sourced from Hashicorp Vault)."
  default = {
    ceu = [
      { name = "ois" },
      { name = "search" }
    ]
    chd = [
      { name = "ois" },
      { name = "search" },
      { name = "chips" }
    ]
    ewf = [
      { name = "ois" },
      { name = "search" },
      { name = "chips" },
      { name = "ef" },
      { name = "ixbrl" },
      { name = "tnep" },
      { name = "trans" },
      { name = "gen" }
    ]
    xml = [
      { name = "ois" },
      { name = "search" },
      { name = "chips" },
      { name = "ef" },
      { name = "ixbrl" },
      { name = "tnep" },
      { name = "trans" },
      { name = "gen" }
    ]
    wck = [
      { name = "chd" },
      { name = "img" },
      { name = "orc" },
      { name = "ehs" },
      { name = "ref" },
      { name = "num" }
    ]
    chs = [
      { name = "auth" }
    ]
    xml-sandpit = [
      { name = "tnep" }
    ]
  }
}

variable "tuxedo_service_log_groups" {
  type = map(list(
    object({
      name                  = string
      log_retention_in_days = optional(number)
      kms_key_id            = optional(string)
    })
  ))
  description = "A map of lists whose keys represent Tuxedo service groups. Each list object represents a pair of CloudWatch log groups for a single Tuxedo service (each log group name will be suffixed with '-stderr' or '-stdout' respectively) and is expected to specify at least a 'name' attribute. Optional 'log_retention_in_days' and 'kms_key_id' attributes can be used to override the default values ('log_retention_in_days' defaults to the value of the 'default_log_retention_in_days' variable, and 'kms_key_id' defaults to a KMS key identifier value sourced from Hashicorp Vault)."
  default = {
    ceu = [
      { name = "CHG" },
      { name = "CS" },
      { name = "DBG" },
      { name = "ES" },
      { name = "Sys" }
    ]
    chd = [
      { name = "CHG" },
      { name = "DBG" },
      { name = "ES" },
      { name = "CS" },
      { name = "Sys" }
    ]
    ewf = [
      { name = "CHG" },
      { name = "BE" },
      { name = "DBG" },
      { name = "CS" },
      { name = "Sys" },
      { name = "VXBRL" },
      { name = "VTNEP" },
      { name = "TRXML" }
    ]
    xml = [
      { name = "CHG" },
      { name = "BE" },
      { name = "DBG" },
      { name = "CS" },
      { name = "Sys" },
      { name = "VTNEP" },
      { name = "TRXML" },
      { name = "IXBRL" }
    ]
    wck = [
      { name = "CHG" },
      { name = "DBG" },
      { name = "CS" },
      { name = "ES" },
      { name = "Sys" }
    ]
    chs = [
      { name = "CHG" },
      { name = "BE" },
      { name = "DBG" },
      { name = "Sys" }
    ]
    xml-sandpit = [
      { name = "VTNEP" }
    ]
  }
}

variable "tuxedo_user_log_groups" {
  type = map(list(
    object({
      name                  = string
      log_retention_in_days = optional(number)
      kms_key_id            = optional(string)
    })
  ))
  description = "A map of lists whose keys represent Tuxedo service groups. Each list object represents a single CloudWatch log group for a Tuxedo user log and is expected to specify at least a 'name' attribute. Optional 'log_retention_in_days' and 'kms_key_id' attributes can be used to override the default values ('log_retention_in_days' defaults to the value of the 'default_log_retention_in_days' variable, and 'kms_key_id' defaults to a KMS key identifier value sourced from Hashicorp Vault)."
  default = {
    ceu = [
      { name = "ULOG" }
    ]
    chd = [
      { name = "ULOG" }
    ]
    ewf = [
      { name = "ULOG" }
    ]
    xml = [
      { name = "ULOG" }
    ]
    wck = [
      { name = "ULOG" }
    ]
    chs = [
      { name = "ULOG" }
    ]
    xml-sandpit = [
      { name = "ULOG" }
    ]
  }
}

variable "tuxedo_services" {
  type        = map(map(number))
  description = "A map whose keys represent Tuxedo service groups and associated port numbers."
  default = {
    ceu = {
      ois    = 5000
      search = 5001
    },
    chd = {
      ois    = 4000
      search = 4001
      chips  = 4002
    },
    ewf = {
      ois    = 2000
      search = 2001
      chips  = 2002
      ef     = 2003
      ixbrl  = 2004
      tnep   = 2005
      trans  = 2006
      gen    = 2007
    },
    xml = {
      ois    = 3000
      search = 3001
      chips  = 3002
      ef     = 3003
      ixbrl  = 3004
      tnep   = 3005
      trans  = 3006
      gen    = 3007
    },
    wck = {
      chd = 6000
      img = 6001
      orc = 6002
      ehs = 6003
      ref = 6004
      num = 6005
    }
    chs = {
      auth = 7000
    }
    xml-sandpit = {
      tnep = 8000
    }
  }
}

variable "team" {
  type        = string
  description = "The team name for ownership of this service."
  default     = "Platform"
}

variable "user_data_merge_strategy" {
  type        = string
  default     = "list(append)+dict(recurse_array)+str()"
  description = "Merge strategy to apply to user-data sections for cloud-init."
}

variable "web_subnet_pattern" {
  type        = string
  description = "The pattern to use when filtering for web subnets by 'Name' tag."
  default     = "sub-web-*"
}
