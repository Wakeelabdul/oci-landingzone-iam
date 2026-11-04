output "group_ids" {
  description = "Group key -> OCID."
  value       = { for k, v in oci_identity_group.this : k => v.id }
}

output "dynamic_group_ids" {
  description = "Dynamic group key -> OCID."
  value       = { for k, v in oci_identity_dynamic_group.this : k => v.id }
}

output "policy_ids" {
  description = "Policy key -> OCID."
  value       = { for k, v in oci_identity_policy.this : k => v.id }
}
