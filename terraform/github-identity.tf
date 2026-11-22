# The identity GitHub Actions uses to reach Azure (CD and `terraform plan`).
# The university tenant blocks app registrations, so this is a user-assigned
# managed identity. GitHub proves who it is with a short-lived OIDC token,
# which Azure trusts through the federated credentials below; no secret exists.

locals {
  # GitHub's subject names the owner and repository with their numeric IDs
  # ("repo:RSOcc26@<org-id>/<repo>@<repo-id>:..."), so a repository deleted and
  # recreated under the same name is not trusted. IDs: gh api repos/RSOcc26/<repo> -q .id
  github_owner = "RSOcc26@345155378"

  # Repositories whose CD job deploys to the cluster (.github#26)
  deploying_repos = {
    "gateway"            = 1428425800
    "web"                = 1428425580
    "service-identity"   = 1428407908
    "service-access"     = 1428408036
    "service-workflow"   = 1430868946
    "service-inventory"  = 1430869228
    "service-production" = 1430869327
  }

  # GitHub sets the end of the subject from the job: "environment:<name>" when
  # the job has an environment, "pull_request" for PR runs.
  federated_subjects = merge(
    {
      for pair in setproduct(keys(local.deploying_repos), ["dev", "prod"]) :
      "${pair[0]}-${pair[1]}" => "repo:${local.github_owner}/${pair[0]}@${local.deploying_repos[pair[0]]}:environment:${pair[1]}"
    },
    { "deploy-pr" = "repo:${local.github_owner}/deploy@1430878369:pull_request" },
  )
}

resource "azurerm_user_assigned_identity" "github" {
  name                = "rso-github-actions"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

# Azure allows at most 20 per identity; this creates 15
resource "azurerm_federated_identity_credential" "github" {
  for_each = local.federated_subjects

  name                      = each.key
  user_assigned_identity_id = azurerm_user_assigned_identity.github.id
  issuer                    = "https://token.actions.githubusercontent.com"
  audience                  = ["api://AzureADTokenExchange"]
  subject                   = each.value
}

# CD: download a kubeconfig for helm. The cluster uses Kubernetes RBAC with
# local accounts, so this credential has full rights inside the cluster.
resource "azurerm_role_assignment" "github_cluster_user" {
  scope                = azurerm_kubernetes_cluster.main.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

# terraform plan: read every resource in the group
resource "azurerm_role_assignment" "github_reader" {
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

# terraform plan: read the state and take its lock (a blob lease). The state
# account is created outside Terraform (it stores Terraform's own state).
resource "azurerm_role_assignment" "github_state" {
  scope                = "${azurerm_resource_group.main.id}/providers/Microsoft.Storage/storageAccounts/rsocc26tfstate"
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.github.principal_id
}

# Not secret; stored as GitHub organization variables for azure/login
output "github_client_id" {
  value = azurerm_user_assigned_identity.github.client_id
}

output "github_tenant_id" {
  value = azurerm_user_assigned_identity.github.tenant_id
}
