module "instance_profile" {
  source = "git@github.com:companieshouse/terraform-modules//aws/instance_profile?ref=tags/1.0.40"

  name = "tuxedo-frontend-profile"
  enable_SSM = true
  custom_statements = [
    {
      sid    = "AllowAccessToBuckets",
      effect = "Allow",
      resources = [
        "arn:aws:s3:::shared-services.eu-west-2.releases.ch.gov.uk/*",
        "arn:aws:s3:::shared-services.eu-west-2.releases.ch.gov.uk",
        "arn:aws:s3:::shared-services.eu-west-2.configs.ch.gov.uk/*",
        "arn:aws:s3:::shared-services.eu-west-2.configs.ch.gov.uk"
      ],
      actions = [
        "s3:Get*",
        "s3:List*",
      ]
    }
  ]
}
