# OCI IAM with Terraform + GitHub Actions

Deploy OCI **IAM groups, dynamic groups and policies** from one file: `locals.tf`,
locally or through a GitHub Actions pipeline (validate → plan on PR → approved apply).

## Structure

```
.
├── .github/workflows/terraform.yml  # CI/CD pipeline
├── locals.tf                 # ← EDIT THIS: groups, compartments, dynamic groups, policies
├── main.tf                   # calls modules/iam
├── variables.tf              # input variables (tenancy, user, key, region)
├── providers.tf              # OCI provider (API key auth)
├── versions.tf               # Terraform + provider versions, backend
├── outputs.tf                # OCIDs of created groups / dynamic groups / policies
├── terraform.tfvars.example  # copy to terraform.tfvars
└── modules/iam/              # generic module (for_each over the maps, no changes needed)
```

## Prerequisites

- Terraform >= 1.5
- An OCI user with an API signing key and permission to manage IAM
  (e.g. member of the `Administrators` group)

## Quick start

```bash
git clone https://github.com/Wakeelabdul/oci-landing-zone-iam.git
cd oci-landing-zone-iam

# 1. Credentials
cp terraform.tfvars.example terraform.tfvars
#    edit terraform.tfvars -> tenancy_ocid, user_ocid, fingerprint, private_key_path, region

# 2. Define your IAM objects
#    edit locals.tf -> replace <REPLACE_WITH_...> OCIDs, add/remove groups and policies

# 3. Deploy
terraform init
terraform plan
terraform apply
```

> `region` must be your tenancy **home region** - IAM changes are made there.

## Add a group / policy

Copy an existing entry in `locals.tf` and change it:

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

Run `terraform plan` to review, then `terraform apply`.

## State (local runs)

For local runs state is stored locally (`terraform.tfstate`). For team use, move it to
a remote backend such as OCI Object Storage, and never commit state files
(already covered by `.gitignore`).

## GitHub Actions pipeline

| Event | What runs |
|---|---|
| Pull request to `main` | `validate` + `plan` (plan shown in the job summary) |
| Push / merge to `main` | `validate` + `plan` + `apply` (waits for approval) |
| Manual | Actions → *Terraform OCI IAM* → Run workflow |

Out of the box only **`validate`** runs (fmt + syntax), so a fresh fork stays green.
To enable plan/apply against your tenancy:

1. **Create a state bucket** in OCI Object Storage (versioning recommended).
2. **Add repository secrets** (Settings → Secrets and variables → Actions → Secrets):

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

3. **Add repository variable** `ENABLE_DEPLOY` = `true` (same page → Variables tab).
4. **Create environment** `production` (Settings → Environments) with **Required reviewers**
   — this is the manual approval gate before apply.

State is pulled from the bucket at the start of each run and pushed back after apply
(even if apply fails part-way). Only one apply runs at a time.

**Workflow:** edit `locals.tf` → open PR → review plan → merge → approve apply.

## Notes

- Renaming a group / dynamic group `name` recreates it (user memberships are lost).
- Do not rename map **keys** in `locals.tf` after deployment, for the same reason.
- Policies are created after groups, so a new group and its policy can go in one change.
- Groups in a non-Default identity domain: `Allow group '<Domain>'/'<group>' to ...`

## License

Released under the [Universal Permissive License (UPL) 1.0](LICENSE).
