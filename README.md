# OCI IAM with Terraform + GitHub Actions

Deploy OCI **IAM groups, dynamic groups and policies** from one file: `locals.tf`.

## Structure

```
.
├── .github/workflows/terraform.yml  # validate → plan → apply (approval) → state push
├── locals.tf                 # ← EDIT THIS: groups, compartments, dynamic groups, policies
├── main.tf                   # calls modules/iam
├── variables.tf / providers.tf / versions.tf / outputs.tf
├── terraform.tfvars.example  # for local runs
└── modules/iam/              # for_each over the maps (generic, no changes needed)
```

## Setup

1. Create an Object Storage bucket for the state file (versioning recommended).
2. Create an OCI user with an API key and permission to manage IAM.
3. Add repository secrets (Settings → Secrets and variables → Actions):

| Secret | Example |
|---|---|
| `OCI_TENANCY_OCID` | `ocid1.tenancy.oc1..xxx` |
| `OCI_USER_OCID` | `ocid1.user.oc1..xxx` |
| `OCI_FINGERPRINT` | `aa:bb:...` |
| `OCI_REGION` | home region, e.g. `us-ashburn-1` |
| `OCI_PRIVATE_KEY` | full contents of the `.pem` key |
| `OCI_STATE_BUCKET` | state bucket name |
| `OCI_STATE_NAMESPACE` | Object Storage namespace |
| `OCI_STATE_REGION` | optional, if bucket region differs from `OCI_REGION` |

   Then create an environment named **`production`** (Settings → Environments)
   and add **Required reviewers** — this is the manual approval before apply.

4. Replace the `<REPLACE_WITH_...>` OCIDs in `locals.tf`.
5. Run `terraform init` once locally and commit `.terraform.lock.hcl`.

## Add a group / policy

Copy an existing entry in `locals.tf`, change it, open a pull request.

```hcl
# group
app_readers = { name = "app-readers", description = "Read app resources" }

# policy
app_readers = {
  name           = "pol-app-readers"
  description    = "Read access to PROD app compartment"
  compartment_id = local.compartment_ocids["cmp-prod"]
  statements     = ["Allow group app-readers to read all-resources in compartment cmp-prod-app"]
}
```

Open a pull request → check the plan in the job summary → merge → approve the **apply** job.

## Notes

- Renaming a group/dynamic group **name** recreates it (user memberships are lost).
- Do not rename map **keys** after deployment, for the same reason.
- Groups in a non-Default identity domain: `Allow group '<Domain>'/'<group>' to ...`
- IAM changes are made in the tenancy **home region**.
