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
  path = "applications/${var.aws_account}-${var.region}/tuxedo/tnsnames"
}

data "vault_generic_secret" "chs_subnets" {
  path = "aws-accounts/${var.environment}/vpc/subnets"
}
