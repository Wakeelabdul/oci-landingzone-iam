variable "tenancy_ocid" {
  type        = string
  description = "Tenancy OCID. Groups and dynamic groups are always created here."
}

variable "groups" {
  type = map(object({
    name        = string
    description = string
  }))
  description = "IAM groups to create. Key = Terraform key, name = OCI group name."
  default     = {}
}

variable "dynamic_groups" {
  type = map(object({
    name          = string
    description   = string
    matching_rule = string
  }))
  description = "Dynamic groups to create, each with an OCI matching rule."
  default     = {}
}

variable "policies" {
  type = map(object({
    name           = string
    description    = string
    compartment_id = string
    statements     = list(string)
  }))
  description = "IAM policies. compartment_id = where the policy is attached."
  default     = {}

  validation {
    condition     = alltrue([for p in values(var.policies) : length(p.statements) > 0])
    error_message = "Every policy must have at least one statement."
  }
}

variable "freeform_tags" {
  type        = map(string)
  description = "Free-form tags applied to every group, dynamic group and policy."
  default     = {}
}
