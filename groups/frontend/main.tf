provider "aws" {
  region  = var.region
  version = "~> 2.65.0"
}

terraform {
  backend "s3" {
  }
}

module "frontend" {
  source = "./module-frontend"

  ami_version_pattern = var.ami_version_pattern
  application_subnets = values(data.terraform_remote_state.management_vpc.outputs.management_private_subnet_ids)
  environment         = var.environment
  instance_hostname   = var.instance_hostname
  instance_type       = var.instance_type
  lb_subnet_cidrs     = values(data.terraform_remote_state.management_vpc.outputs.management_private_subnet_cidrs)
  lb_subnet_ids       = values(data.terraform_remote_state.management_vpc.outputs.management_private_subnet_ids)
  lvm_block_devices   = var.lvm_block_devices
  region              = var.region
  service             = var.service
  service_subtype     = var.service_subtype
  ssh_cidrs           = concat(values(data.terraform_remote_state.management_vpc.outputs.vpn_cidrs), values(data.terraform_remote_state.management_vpc.outputs.internal_cidrs))
  ssh_keyname         = var.ssh_keyname
  vpc_id              = data.terraform_remote_state.management_vpc.outputs.management_vpc_id
}

data "terraform_remote_state" "management_vpc" {
  backend = "s3"
  config = {
    bucket = "development-${var.region}.terraform-state.ch.gov.uk"
    key    = "aws-common-infrastructure-terraform/common-${var.region}/networking.tfstate"
    region = var.region
  }
}
