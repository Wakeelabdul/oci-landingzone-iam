###############################################################################
# OCI IAM - Generic locals.tf
#
# PURPOSE
#   Single place to define the IAM objects you want to deploy:
#     1. IAM Groups
#     2. Compartment OCIDs (lookup map used by policies)
#     3. Dynamic Groups
#     4. IAM Policies
#
# HOW IT WORKS
#   - Add / remove entries in the maps below. Nothing else needs to change.
#   - Each map is looped over with for_each in main.tf (see example at bottom).
#   - The map KEY (e.g. "app_admins") is the Terraform resource key - keep it
#     unique and do not rename it after deployment, or Terraform will
#     destroy and recreate the object.
#
# REQUIRED VARIABLES
#   var.tenancy_ocid  - OCID of the tenancy (root compartment)
#
# NAMING CONVENTION USED IN EXAMPLES  (change to suit your org)
#   Groups          : <team>-<env>-<role>        e.g. app-prod-admins
#   Dynamic Groups  : dg-<env>-<service>         e.g. dg-prod-functions
#   Policies        : pol-<env>-<purpose>        e.g. pol-dev-developers
#   Compartments    : cmp-<env>[-<workload>]     e.g. cmp-prod-app
###############################################################################

locals {

  #############################################################################
  # 1. IAM GROUPS
  # ---------------------------------------------------------------------------
  # Groups hold users. Policies grant permissions to groups.
  #
  # Format:
  #   <key> = { name = "<group-name>", description = "<what it is for>" }
  #
  # "name" is what you reference in policy statements:
  #   "Allow group <name> to ..."
  #############################################################################
  groups = {

    # --- Tenancy-wide groups ---
    cloud_admins   = { name = "cloud-admins", description = "Full administrative access to the tenancy" }
    read_only      = { name = "read-only", description = "Read-only access to all resources" }
    network_admins = { name = "network-admins", description = "Manage VCNs, subnets, DRGs, security lists" }
    security_team  = { name = "security-team", description = "Read access for audit, Cloud Guard and logging" }
    support_admins = { name = "support-admins", description = "Raise and manage Oracle Support SRs" }

    # --- Environment-specific groups (repeat the pattern per env) ---
    dev_developers = { name = "app-dev-developers", description = "Manage resources in DEV compartment" }
    uat_developers = { name = "app-uat-developers", description = "Use resources in UAT compartment" }
    prod_operators = { name = "app-prod-operators", description = "Operate (use/read) resources in PROD" }

    # --- Service account groups (for API keys / CI-CD pipelines) ---
    cicd_svc = { name = "svc-cicd", description = "CI/CD pipeline service account" }
  }

  #############################################################################
  # 2. COMPARTMENT OCIDs
  # ---------------------------------------------------------------------------
  # Lookup map: compartment name -> OCID.
  # Used to decide WHERE each policy is attached (compartment_id).
  #
  # The NAME must match the compartment name you write in policy statements,
  # e.g. "... in compartment cmp-prod".
  # For nested compartments see the path rule in section 4 (Policies).
  #############################################################################
  compartment_ocids = {
    "cmp-dev"  = "<REPLACE_WITH_DEV_COMPARTMENT_OCID>"
    "cmp-uat"  = "<REPLACE_WITH_UAT_COMPARTMENT_OCID>"
    "cmp-prod" = "<REPLACE_WITH_PROD_COMPARTMENT_OCID>"

    # Optional child compartments
    "cmp-prod-app"     = "<REPLACE_WITH_PROD_APP_COMPARTMENT_OCID>"
    "cmp-prod-db"      = "<REPLACE_WITH_PROD_DB_COMPARTMENT_OCID>"
    "cmp-prod-network" = "<REPLACE_WITH_PROD_NETWORK_COMPARTMENT_OCID>"
  }

  #############################################################################
  # 3. DYNAMIC GROUPS
  # ---------------------------------------------------------------------------
  # Dynamic groups hold RESOURCES (instances, functions, OKE pods, etc.)
  # instead of users, so those resources can call OCI APIs without API keys
  # (instance / resource principals).
  #
  # Format:
  #   <key> = {
  #     name          = "<dg-name>"
  #     description   = "<what it is for>"
  #     matching_rule = "<rule>"
  #   }
  #
  # Common matching rule patterns:
  #   All instances in a compartment:
  #     "ALL {instance.compartment.id = '<compartment_ocid>'}"
  #   A specific resource type in a compartment:
  #     "ALL {resource.type = 'fnfunc', resource.compartment.id = '<compartment_ocid>'}"
  #   One specific resource:
  #     "ALL {resource.type = '<type>', resource.id = '<resource_ocid>'}"
  #   Match any of several rules:
  #     "ANY {<rule1>, <rule2>}"
  #############################################################################
  dynamic_groups = {

    # Example 1: every compute instance in the PROD app compartment
    dg_prod_instances = {
      name          = "dg-prod-instances"
      description   = "All compute instances in PROD app compartment"
      matching_rule = "ALL {instance.compartment.id = '${local.compartment_ocids["cmp-prod-app"]}'}"
    }

    # Example 2: all OCI Functions in the DEV compartment
    dg_dev_functions = {
      name          = "dg-dev-functions"
      description   = "All OCI Functions in DEV compartment"
      matching_rule = "ALL {resource.type = 'fnfunc', resource.compartment.id = '${local.compartment_ocids["cmp-dev"]}'}"
    }

    # Example 3: one specific resource by OCID (e.g. an OAC / DIS / OKE resource)
    dg_uat_single_resource = {
      name          = "dg-uat-analytics"
      description   = "Specific analytics instance in UAT"
      matching_rule = "ALL {resource.type = 'analyticsinstance', resource.id = '<REPLACE_WITH_RESOURCE_OCID>'}"
    }
  }

  #############################################################################
  # 4. IAM POLICIES
  # ---------------------------------------------------------------------------
  # Format:
  #   <key> = {
  #     name           = "<policy-name>"
  #     description    = "<what it grants>"
  #     compartment_id = <where the policy is ATTACHED>
  #     statements     = [ "<statement>", ... ]
  #   }
  #
  # Where to attach (compartment_id):
  #   - Statements using "in tenancy"         -> var.tenancy_ocid
  #   - Statements using "in compartment X"   -> X or any parent of X
  #
  # Compartment path is RELATIVE to where the policy is attached:
  #   Attached at tenancy  -> "in compartment cmp-prod:cmp-prod-app"
  #   Attached at cmp-prod -> "in compartment cmp-prod-app"
  #
  # Policies are created AFTER groups/dynamic groups (handled in the module),
  # so you can add a group and its policy in the same commit.
  #
  # Statement syntax:
  #   Allow <subject> to <verb> <resource-type> in <location> [where <conditions>]
  #
  #   subject : group <name> | dynamic-group <name> | service <name> | any-user
  #   verb    : inspect < read < use < manage   (least -> most privilege)
  #   resource: all-resources | instance-family | object-family |
  #             virtual-network-family | database-family | buckets | ...
  #   location: tenancy | compartment <name> | compartment <parent>:<child>
  #############################################################################
  policies = {

    # ===========================================================================
    # TENANCY-LEVEL POLICIES  (attached at root)
    # ===========================================================================

    # Full admin access
    tenancy_admins = {
      name           = "pol-tenancy-admins"
      description    = "Full access for cloud administrators"
      compartment_id = var.tenancy_ocid
      statements = [
        "Allow group cloud-admins to manage all-resources in tenancy",
      ]
    }

    # Read-only across the tenancy
    tenancy_read_only = {
      name           = "pol-tenancy-read-only"
      description    = "Read-only access to all resources"
      compartment_id = var.tenancy_ocid
      statements = [
        "Allow group read-only to read all-resources in tenancy",
      ]
    }

    # Oracle Support tickets
    support_admins = {
      name           = "pol-support-admins"
      description    = "Manage Oracle Support requests"
      compartment_id = var.tenancy_ocid
      statements = [
        "Allow group support-admins to manage tickets in tenancy",
      ]
    }

    # Example of a SERVICE policy (letting an OCI service act on your resources)
    service_cloudguard = {
      name           = "pol-service-cloudguard"
      description    = "Allow Cloud Guard service to read tenancy resources"
      compartment_id = var.tenancy_ocid
      statements = [
        "Allow service cloudguard to read all-resources in tenancy",
      ]
    }

    # ===========================================================================
    # DEV POLICIES
    # ===========================================================================

    # Developers have full control in DEV only
    dev_developers = {
      name           = "pol-dev-developers"
      description    = "Developers manage all resources in DEV"
      compartment_id = local.compartment_ocids["cmp-dev"]
      statements = [
        "Allow group app-dev-developers to manage all-resources in compartment cmp-dev",
      ]
    }

    # Dynamic group example: Functions in DEV can read Object Storage
    dev_functions = {
      name           = "pol-dev-functions"
      description    = "DEV Functions can read buckets/objects"
      compartment_id = local.compartment_ocids["cmp-dev"]
      statements = [
        "Allow dynamic-group dg-dev-functions to read object-family in compartment cmp-dev",
      ]
    }

    # ===========================================================================
    # UAT POLICIES
    # ===========================================================================

    # Developers can USE (not create/delete) resources in UAT
    uat_developers = {
      name           = "pol-uat-developers"
      description    = "Developers use resources in UAT"
      compartment_id = local.compartment_ocids["cmp-uat"]
      statements = [
        "Allow group app-uat-developers to use all-resources in compartment cmp-uat",
      ]
    }

    # ===========================================================================
    # PROD POLICIES
    # ===========================================================================

    # Operators: read everything, restart instances, nothing destructive
    prod_operators = {
      name           = "pol-prod-operators"
      description    = "Operators read PROD and manage instance lifecycle"
      compartment_id = local.compartment_ocids["cmp-prod"]
      statements = [
        "Allow group app-prod-operators to read all-resources in compartment cmp-prod",
        "Allow group app-prod-operators to use instance-family in compartment cmp-prod-app",
      ]
    }

    # Network team manages networking in PROD
    prod_network = {
      name           = "pol-prod-network"
      description    = "Network admins manage PROD networking"
      compartment_id = local.compartment_ocids["cmp-prod"]
      statements = [
        "Allow group network-admins to manage virtual-network-family in compartment cmp-prod-network",
      ]
    }

    # Dynamic group example: PROD instances read secrets from Vault
    prod_instances = {
      name           = "pol-prod-instances"
      description    = "PROD instances read Vault secrets"
      compartment_id = local.compartment_ocids["cmp-prod"]
      statements = [
        "Allow dynamic-group dg-prod-instances to read secret-family in compartment cmp-prod-app",
      ]
    }

    # Conditional statement example (WHERE clause)
    prod_cicd = {
      name           = "pol-prod-cicd"
      description    = "CI/CD can manage objects in one specific bucket only"
      compartment_id = local.compartment_ocids["cmp-prod"]
      statements = [
        "Allow group svc-cicd to manage objects in compartment cmp-prod where target.bucket.name = 'artifacts-bucket'",
      ]
    }
  }
}

