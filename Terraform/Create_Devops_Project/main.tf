terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = "~> 0.1"
    }
  }
}


# Define the Azure DevOps project
resource "azuredevops_project" "abeltestproject" {
  name       = "ExampleProject"
  visibility = "private"
}
# Define a repository in the project
resource "azuredevops_git_repository" "repo-test" {
  project_id = azuredevops_project.abeltestproject.id
  name       = "example-repo"
  initialization {
    init_type = "Clean"
  }
  lifecycle {
    ignore_changes = [
      # Ignore changes to initialization to support importing existing repositories
      # Given that a repo now exists, either imported into terraform state or created by terraform,
      # we don't care for the configuration of initialization against the existing resource
      initialization,
    ]
  }
}


resource "azuredevops_serviceendpoint_github" "github_connection" {
  project_id            = azuredevops_project.abeltestproject.id
  service_endpoint_name = "Example GitHub Personal Access Token"

  auth_personal {
    # Also can be set with AZDO_GITHUB_SERVICE_CONNECTION_PAT environment variable
    personal_access_token = var.github_token
  }
}

resource "azuredevops_build_definition" "sync_pipeline" {
  project_id = azuredevops_project.abeltestproject.id
  name       = "Sync GitHub to Azure DevOps"
  path       = "\\"
  ci_trigger {
    use_yaml = true
  }
  repository {
    repo_type   = "GitHub"
    repo_id     = "GET https://api.github.com/repos/Abel-Dagnew/myproject"
    branch_name = "main"  # Change this to your branch
    yml_path    = "azure-pipelines.yml"
    service_connection_id = azuredevops_serviceendpoint_github.github_connection.id
  }
}
