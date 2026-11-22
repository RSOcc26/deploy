# Terraform

The Azure infrastructure as code (ADR-0004): the resource group `rso-rg`, the
AKS cluster `rso-cluster` and the identity GitHub Actions uses to reach Azure.
The cluster was first created in the portal and adopted with the `import`
blocks in `main.tf`; nothing was recreated.

| File | Contents |
|---|---|
| `versions.tf` | Terraform and provider versions, remote state, provider settings |
| `main.tf` | Resource group and the import blocks |
| `aks.tf` | The cluster |
| `github-identity.tf` | Managed identity `rso-github-actions`, its federated credentials (GitHub OIDC) and roles |

## State

Stored in Azure Storage: account `rsocc26tfstate`, container `tfstate`, blob
`companycentral.tfstate`, signed in with Entra ID (no access keys). The account
was created by hand once, because Terraform cannot store its state in
something it has not created yet. Terraform takes a lock (a blob lease) on
every plan and apply, so two people cannot apply at once.

You need **Storage Blob Data Contributor** on the account, and Owner on
`rso-rg` to apply role assignments.

## Use

```sh
az login --tenant <tenant-id>
export TF_VAR_subscription_id=$(az account show --query id -o tsv)
cd terraform
terraform init
terraform plan -out=change.tfplan    # review it
terraform apply change.tfplan && rm change.tfplan
```

Apply a saved plan: it applies exactly what you reviewed and needs no prompt.

## CI

The `Terraform` job in `.github/workflows/validate.yml` checks formatting and
validates on every pull request and push, and on pull requests also runs
`terraform plan` against the live infrastructure (read-only identity). Applying
stays a manual step.

## Guards

- `prevent_destroy` on the resource group and the cluster: a plan that would
  delete or replace them fails instead.
- `ignore_changes` on the node count (the autoscaler owns it).
- The Kubernetes version is not pinned: Azure applies patch releases itself.
