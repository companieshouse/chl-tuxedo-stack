module "instance_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.62"
  name = "tuxedo-frontend-profile"

  cw_log_group_arns = flatten([
    [aws_cloudwatch_log_group.cloudwatch.arn],
    [for tuxedo_server_type_key, tuxedo_services in var.tuxedo_services : "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:${var.service_subtype}-${var.service}-${tuxedo_server_type_key}-*:*"]
  ])

  enable_SSM = true
  kms_key_refs = [
    local.ssm_kms_key_id
  ]
  s3_buckets_write = [local.session_manager_bucket_name]
}
