output "group_ids" {
  description = "Group key -> OCID."
  value       = module.iam.group_ids
}

output "dynamic_group_ids" {
  description = "Dynamic group key -> OCID."
  value       = module.iam.dynamic_group_ids
}

output "policy_ids" {
  description = "Policy key -> OCID."
  value       = module.iam.policy_ids
}
