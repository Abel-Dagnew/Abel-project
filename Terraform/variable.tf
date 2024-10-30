variable "personal_access_token" {
  description = "Personal Access Token for Azure DevOps"
  type        = string
  sensitive   = true  # Marking this variable as sensitive
}

variable "github_token" {
  description = "GitHub Personal Access Token (PAT) to authenticate Azure DevOps with GitHub."
  type        = string
  sensitive   = true
 
}