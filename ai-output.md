To design a GitHub-first CI/CD setup for MLOps on AWS with strong governance, we need to consider various aspects of the development lifecycle, including branching strategies, code reviews, CI/CD workflows, and security. Below is a comprehensive plan addressing each of these areas:

### Branching Model Options

#### Trunk-Based Development
- **Pros:**
  - Encourages frequent integration, reducing merge conflicts.
  - Simplifies the release process with fewer long-lived branches.
  - Ideal for teams practicing continuous delivery.
- **Cons:**
  - Requires discipline to maintain code quality.
  - May not suit teams with less mature CI/CD practices.

#### GitFlow
- **Pros:**
  - Clear separation of development, release, and hotfix branches.
  - Suitable for teams with less frequent releases.
- **Cons:**
  - Can become complex with multiple long-lived branches.
  - May slow down the integration process.

**Guidance:**
- **Small Teams/Frequent Releases:** Trunk-Based Development is recommended.
- **Larger Teams/Infrequent Releases:** GitFlow may be more appropriate.

### Branch Protections
- **Required Reviews:** At least 2 reviews for each PR.
- **Status Checks:** Must pass all required checks (lint, test, security scan, plan).
- **Linear History:** Enforce linear history to avoid complex merge commits.
- **Signed Commits:** Require signed commits for authenticity.
- **Restricted Merges:** Only allow squash merges to maintain a clean history.

### CODEOWNERS Examples
```plaintext
# CODEOWNERS file
# Assign ownership to specific teams or individuals

# Data processing scripts
data-processing/ @data-team

# Model training code
model-training/ @ml-team

# Deployment scripts
deployment/ @devops-team

# Global settings
* @project-lead
```
- **Required Reviews from Owners:** Ensure that changes to specific areas are reviewed by designated owners.

### Required Status Checks and Environment Protection Rules
- **Status Checks:**
  - Linting: Ensure code style consistency.
  - Testing: Run unit and integration tests.
  - Security Scan: Check for vulnerabilities.
  - Plan: Validate infrastructure changes (e.g., Terraform plan).

- **Environment Protection Rules:**
  - **Dev:** Automatic deployments allowed.
  - **Stage:** Require manual approval for deployments.
  - **Prod:** Require manual approval and additional checks (e.g., performance tests).

### GitHub Actions: Reusable Workflows
- **Reusable Workflows:**
  - **Data Checks:** Validate data quality and schema.
  - **Train:** Execute model training with hyperparameter tuning.
  - **Eval:** Evaluate model performance metrics.
  - **Register:** Register the model in a model registry.
  - **Deploy:** Deploy the model to the target environment.

- **Matrices and Caches/Artifacts:**
  - Use matrices for testing across different environments or configurations.
  - Cache dependencies to speed up builds.
  - Store artifacts like model binaries for later stages.

- **Concurrency:**
  - Limit concurrent runs to manage resource usage.

### OIDC Role Trust Policy + Least-Privilege IAM Policies
- **OIDC Role Trust Policy:**
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringEquals": {
            "token.actions.githubusercontent.com:sub": "repo:<ORG>/<REPO>:ref:refs/heads/main"
          }
        }
      }
    ]
  }
  ```

- **Least-Privilege IAM Policies:**
  - Define specific permissions for each job, e.g., S3 access for data jobs, SageMaker for training, etc.

### Example PR Templates and Labels
- **PR Template:**
  ```markdown
  ## Description
  - Brief description of the changes.

  ## Checklist
  - [ ] Code is linted
  - [ ] Tests are passing
  - [ ] Security checks passed
  - [ ] Changes documented

  ## Risk Assessment
  - Describe potential risks and mitigation strategies.

  ## Rollout Plan
  - Outline the deployment plan.

  ## Rollback Plan
  - Describe how to rollback if needed.
  ```

- **Labels:**
  - `bug`, `feature`, `enhancement`, `urgent`, `needs-review`, `security`

### Release/Versioning Strategy and Tags
- **Strategy:**
  - Use Semantic Versioning (e.g., v1.0.0).
  - Automate changelog generation using tools like `release-drafter`.

- **Tags:**
  - Tag releases in GitHub with version numbers.
  - Use tags to trigger deployment workflows.

This setup provides a robust framework for managing MLOps workflows on AWS using GitHub, ensuring strong governance and efficient collaboration.