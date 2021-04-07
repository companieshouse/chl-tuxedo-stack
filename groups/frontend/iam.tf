module "instance_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.40"

  name = "tuxedo-frontend-profile"
  enable_SSM = true
  cw_log_group_arns = [for log_group in aws_cloudwatch_log_group.logs : log_group.arn]
}
