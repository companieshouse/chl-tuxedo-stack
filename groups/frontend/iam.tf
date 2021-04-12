module "instance_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.62"
  name = "tuxedo-frontend-profile"

  cw_log_group_arns = [for log_group in aws_cloudwatch_log_group.logs : log_group.arn]
  enable_SSM = true
  kms_key_refs = [
    local.ssm_kms_key_id
  ]
  s3_buckets_write = [local.session_manager_bucket_name]
}
