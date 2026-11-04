###############################################################################
# Module: iam
# Creates IAM groups, dynamic groups and policies from the maps passed in.
#
# NOTE: changing a group or dynamic group "name" forces REPLACEMENT
# (destroy + create). For groups this removes all user memberships.
###############################################################################

# -----------------------------------------------------------------------------
# IAM Groups (always created in the tenancy / root compartment)
# -----------------------------------------------------------------------------
resource "oci_identity_group" "this" {
  for_each       = var.groups
  compartment_id = var.tenancy_ocid
  name           = each.value.name
  description    = each.value.description
  freeform_tags  = var.freeform_tags
}

# -----------------------------------------------------------------------------
# Dynamic Groups (always created in the tenancy / root compartment)
# -----------------------------------------------------------------------------
resource "oci_identity_dynamic_group" "this" {
  for_each       = var.dynamic_groups
  compartment_id = var.tenancy_ocid
  name           = each.value.name
  description    = each.value.description
  matching_rule  = each.value.matching_rule
  freeform_tags  = var.freeform_tags
}

# -----------------------------------------------------------------------------
# Policies (attached to the compartment given per policy)
# depends_on: OCI rejects a policy that references a group / dynamic group
# that does not exist yet, so policies are created last.
# -----------------------------------------------------------------------------
resource "oci_identity_policy" "this" {
  for_each       = var.policies
  compartment_id = each.value.compartment_id
  name           = each.value.name
  description    = each.value.description
  statements     = each.value.statements
  freeform_tags  = var.freeform_tags

  depends_on = [
    oci_identity_group.this,
    oci_identity_dynamic_group.this,
  ]
}
