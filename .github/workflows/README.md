# GitHub Actions CI/CD Pipeline

This directory contains the GitHub Actions workflows for the ContractAnalyzer project's CI/CD pipeline.

## Overview

The CI/CD pipeline implements a comprehensive build, test, security scan, and deployment automation for all microservices in the ContractAnalyzer project.

## Workflows

### 1. Main CI/CD Pipeline (`ci.yml`)

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` branch

**Services Matrix:**
- `api-gateway`
- `auth`
- `analysis`
- `citation`
- `ocr-wrapper`

**Pipeline Stages:**

#### Build Matrix Job
- **Lint**: ESLint validation for each service
- **Test**: Jest unit tests with 70% coverage threshold
- **Coverage**: Upload coverage reports to Codecov

#### Security Scan Job
- **Node.js Security**: Snyk vulnerability scanning
- **Dependency Check**: High severity threshold

#### Build and Push Job
- **Docker Build**: Multi-stage Docker builds
- **Registry Push**: Push to GitHub Container Registry (GHCR)
- **Image Security**: Snyk Docker image scanning
- **Caching**: Optimized build caching

#### Helm Deploy Job (Main branch only)
- **Chart Update**: Automatic Helm values.yaml updates
- **Auto-bump**: Create deployment branches
- **ArgoCD Integration**: Automated GitOps deployment

### 2. Reusable Workflow Template (`_templates/reuse.yaml`)

Provides reusable workflow steps for:
- Environment setup (Node.js 20, pnpm)
- Dependency caching
- Lint, test, security, and build operations
- Docker image management

## Configuration

### Required Secrets

Add these secrets to your GitHub repository:

```bash
# Snyk security scanning
SNYK_TOKEN=your_snyk_token_here

# GitHub Container Registry (automatically provided)
GITHUB_TOKEN=automatically_provided
```

### Environment Variables

- `NODE_VERSION`: Node.js version (default: '20')
- `COVERAGE_THRESHOLD`: Test coverage threshold (default: 70)
- `REGISTRY`: Container registry (ghcr.io)

## Branch Protection Rules

Configure the following branch protection rules for the `main` branch:

### Required Status Checks
- `Build Matrix (api-gateway)`
- `Build Matrix (auth)`
- `Build Matrix (analysis)`
- `Build Matrix (citation)`
- `Build Matrix (ocr-wrapper)`
- `Security Scan (api-gateway)`
- `Security Scan (auth)`
- `Security Scan (analysis)`
- `Security Scan (citation)`
- `Security Scan (ocr-wrapper)`
- `PR Status Check`

### Protection Settings
```yaml
# GitHub Branch Protection Configuration
protection_rules:
  main:
    required_status_checks:
      strict: true
      contexts:
        - "Build Matrix (api-gateway)"
        - "Build Matrix (auth)"
        - "Build Matrix (analysis)"
        - "Build Matrix (citation)"
        - "Build Matrix (ocr-wrapper)"
        - "Security Scan (api-gateway)"
        - "Security Scan (auth)"
        - "Security Scan (analysis)"
        - "Security Scan (citation)"
        - "Security Scan (ocr-wrapper)"
        - "PR Status Check"
    enforce_admins: true
    required_pull_request_reviews:
      required_approving_review_count: 1
      dismiss_stale_reviews: true
      require_code_owner_reviews: true
    restrictions: null
```

## Docker Images

Images are built and pushed to GitHub Container Registry:

```
ghcr.io/[owner]/[repo]/api-gateway:latest
ghcr.io/[owner]/[repo]/auth:latest
ghcr.io/[owner]/[repo]/analysis:latest
ghcr.io/[owner]/[repo]/citation:latest
ghcr.io/[owner]/[repo]/ocr-wrapper:latest
```

### Image Tags
- `latest`: Latest main branch build
- `{branch-name}`: Branch-specific builds
- `{sha}`: Commit-specific builds
- `{branch}-{sha}`: Combined branch and commit tags

## ArgoCD Integration

The pipeline automatically creates deployment branches for ArgoCD:

1. **Auto-bump Branch**: `infra/auto-bump-{sha}-{service}`
2. **Helm Updates**: Updates `deploy/charts/contract-analyzer/charts/{service}/values.yaml`
3. **Pull Requests**: Creates PRs for ArgoCD to detect and sync

### ArgoCD Configuration

Ensure ArgoCD is configured to:
- Monitor the repository for `infra/auto-bump-*` branches
- Auto-sync enabled with pruning
- Self-heal enabled for automatic recovery

## Local Development

### Running Tests Locally
```bash
cd contract-analyzer

# Install dependencies
pnpm install

# Run lint for specific service
pnpm nx lint api-gateway

# Run tests with coverage
pnpm nx test api-gateway --coverage

# Run all services
for service in api-gateway auth analysis citation ocr-wrapper; do
  pnpm nx lint $service
  pnpm nx test $service --coverage
done
```

### Building Docker Images Locally
```bash
# Build specific service
docker build -f contract-analyzer/apps/Dockerfile -t contract-analyzer/api-gateway:local .

# Build with service argument
docker build -f contract-analyzer/apps/auth/Dockerfile -t contract-analyzer/auth:local .
```

## Troubleshooting

### Common Issues

1. **Coverage Threshold Failures**
   - Ensure tests achieve 70% coverage
   - Check Jest configuration in each service

2. **Docker Build Failures**
   - Verify Dockerfile paths
   - Check build context and dependencies

3. **Snyk Security Failures**
   - Review vulnerability reports
   - Update dependencies or add exceptions

4. **Helm Deployment Issues**
   - Verify values.yaml syntax
   - Check ArgoCD application configuration

### Debug Commands

```bash
# Check workflow status
gh run list --workflow=ci.yml

# View specific run logs
gh run view [run-id] --log

# Check branch protection
gh api repos/:owner/:repo/branches/main/protection
```

## Monitoring and Observability

- **Coverage Reports**: Available in Codecov dashboard
- **Security Reports**: Available in Snyk dashboard
- **Build Metrics**: Available in GitHub Actions insights
- **Deployment Status**: Monitored through ArgoCD UI

## Contributing

When contributing to the CI/CD pipeline:

1. Test changes in a feature branch
2. Ensure all status checks pass
3. Update documentation for new features
4. Follow the established patterns for consistency

## Support

For issues with the CI/CD pipeline:
1. Check the GitHub Actions logs
2. Review the troubleshooting section
3. Consult the team's DevOps documentation
4. Create an issue with detailed error information
