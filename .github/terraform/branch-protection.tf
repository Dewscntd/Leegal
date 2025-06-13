# Terraform configuration for GitHub branch protection
# Usage: terraform init && terraform plan && terraform apply

terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

# Configure the GitHub Provider
provider "github" {
  token = var.github_token
  owner = var.github_owner
}

# Variables
variable "github_token" {
  description = "GitHub personal access token"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
}

variable "repository_name" {
  description = "GitHub repository name"
  type        = string
  default     = "Leegal"
}

# Branch protection rule for main branch
resource "github_branch_protection" "main" {
  repository_id = var.repository_name
  pattern       = "main"

  # Require pull request reviews
  required_pull_request_reviews {
    required_approving_review_count      = 1
    dismiss_stale_reviews               = true
    require_code_owner_reviews          = true
    restrict_dismissals                 = false
  }

  # Require status checks
  required_status_checks {
    strict = true
    contexts = [
      "Build Matrix (api-gateway)",
      "Build Matrix (auth)",
      "Build Matrix (analysis)", 
      "Build Matrix (citation)",
      "Build Matrix (ocr-wrapper)",
      "Security Scan (api-gateway)",
      "Security Scan (auth)",
      "Security Scan (analysis)",
      "Security Scan (citation)", 
      "Security Scan (ocr-wrapper)",
      "PR Status Check"
    ]
  }

  # Additional protections
  enforce_admins         = true
  allows_deletions      = false
  allows_force_pushes   = false
  require_signed_commits = false

  # Require conversation resolution
  require_conversation_resolution = true
}

# Output the protection rule details
output "branch_protection_url" {
  value = "https://github.com/${var.github_owner}/${var.repository_name}/settings/branches"
}
