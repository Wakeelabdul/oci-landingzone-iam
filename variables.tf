# In GitHub Actions these are supplied as TF_VAR_<name> env vars mapped from repo secrets.
# For local runs, copy terraform.tfvars.example to terraform.tfvars.

variable "tenancy_ocid" {
  type        = string
  description = "Tenancy OCID. IAM groups and dynamic groups are created here."
}

variable "region" {
  type        = string
  description = "OCI home region (IAM changes are made in the home region), e.g. us-ashburn-1."
}

variable "user_ocid" {
  type        = string
  description = "OCID of the user (or service user) Terraform authenticates as."
}

variable "fingerprint" {
  type        = string
  description = "Fingerprint of the API signing key uploaded for user_ocid."
}

variable "private_key_path" {
  type        = string
  description = "Path to the API private key (.pem). In CI the workflow writes the key secret to a file."
}

variable "freeform_tags" {
  type        = map(string)
  description = "Tags applied to every IAM object created."
  default = {
    "ManagedBy" = "Terraform"
  }
}
