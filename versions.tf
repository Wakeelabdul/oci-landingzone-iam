terraform {
  required_version = ">= 1.5.0"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 7.0"
    }
  }

  # State is stored locally inside the CI job, then pulled from / pushed to
  # an OCI Object Storage bucket by the workflow (see .github/workflows/terraform.yml).
  backend "local" {}
}
