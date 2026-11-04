# Deploys everything defined in locals.tf through the IAM module.
module "iam" {
  source         = "./modules/iam"
  tenancy_ocid   = var.tenancy_ocid
  groups         = local.groups
  dynamic_groups = local.dynamic_groups
  policies       = local.policies
  freeform_tags  = var.freeform_tags
}
