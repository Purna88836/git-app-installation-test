To set up a comprehensive CI/CD pipeline for MLOps on AWS using GitHub, here's a detailed plan that includes branching strategies, GitHub Actions workflows, Terraform scripts, and governance practices tailored to your environments (dev, qa, qc, prod).

### 1. Branching Model Options

#### Trunk-Based Development
- **Pros**: Simplifies merging, encourages frequent integration, reduces merge conflicts.
- **Cons**: Requires robust testing and CI practices to ensure stability.
- **Best for**: Smaller teams or projects with continuous delivery.

#### GitFlow
- **Pros**: Clear separation of development, testing, and production stages.
- **Cons**: More complex, can slow down the release process.
- **Best for**: Larger teams or projects with scheduled releases.

**Recommendation**: Given your multiple environments (dev, qa, qc, prod), GitFlow might be more suitable to manage releases and testing phases effectively.

### 2. Branch Protections

- **Master Branch**: 
  - Require pull request reviews from code owners.
  - Require status checks to pass before merging.
  - Enforce linear history.
  - Require signed commits.
  - Restrict who can push to the branch.

- **Feature/Development Branches**:
  - Require status checks to pass before merging.

### 3. CODEOWNERS Example

```plaintext
# CODEOWNERS file
*       @team-lead @devops-lead

/infrastructure/ @infra-team
/models/ @ml-team
```

### 4. Required Status Checks

- **Linting**: Ensure code quality.
- **Testing**: Run unit and integration tests.
- **Security Scanning**: Check for vulnerabilities.
- **Plan**: Validate infrastructure changes with Terraform plan.

### 5. GitHub Actions Workflow

Create a reusable workflow for the CI/CD pipeline:

```yaml
# .github/workflows/cicd.yml
name: CI/CD Pipeline

on:
  push:
    branches:
      - 'feature/*'
      - 'release/*'
      - 'master'

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.8'

    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt

    - name: Lint and Test
      run: |
        pip install flake8 pytest
        flake8 .
        pytest

  deploy:
    runs-on: ubuntu-latest
    needs: build
    if: github.ref == 'refs/heads/master'

    steps:
    - name: Checkout code
      uses: actions/checkout@v2

    - name: Set up Terraform
      uses: hashicorp/setup-terraform@v1
      with:
        terraform_version: 1.0.0

    - name: Terraform Init
      run: terraform init

    - name: Terraform Apply
      run: terraform apply -auto-approve

    - name: Deploy SageMaker Pipeline
      run: python deploy_sagemaker.py
```

### 6. Terraform Configuration

Define AWS infrastructure using Terraform:

```hcl
# infrastructure/main.tf
provider "aws" {
  region = "us-west-2"
}

resource "aws_sagemaker_model" "example_model" {
  name                  = "example-model"
  execution_role_arn    = aws_iam_role.sagemaker_execution_role.arn
  primary_container {
    image               = "123456789012.dkr.ecr.us-west-2.amazonaws.com/my-sagemaker-image:latest"
    model_data_url      = "s3://my-bucket/model.tar.gz"
  }
}

resource "aws_iam_role" "sagemaker_execution_role" {
  name = "sagemaker-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "sagemaker.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "sagemaker_policy_attachment" {
  role       = aws_iam_role.sagemaker_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}
```

### 7. OIDC Role Trust Policy and IAM Policies

Configure OIDC for GitHub Actions:

```hcl
# infrastructure/oidc.tf
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:sub" = "repo:your-org/your-repo:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSageMakerFullAccess"
}
```

### 8. PR Templates and Labels

Create a pull request template:

```markdown
<!-- .github/pull_request_template.md -->
## Description

Please include a summary of the changes and the related issue. 

## Checklist

- [ ] Code is linted and tested
- [ ] Documentation is updated
- [ ] Changes are backward-compatible
- [ ] Rollback plan is defined

## Labels

- [ ] bug
- [ ] enhancement
- [ ] documentation
```

### 9. Release/Versioning Strategy

Use semantic versioning and automate changelog generation with tools like `semantic-release`.

### Notes
- Adjust Terraform and Python scripts to fit your specific SageMaker pipeline requirements.
- Ensure AWS credentials and permissions are correctly configured for GitHub Actions.
- Regularly review and update IAM policies to adhere to the principle of least privilege.

This setup provides a robust framework for managing your MLOps pipeline on AWS using GitHub, ensuring strong governance and efficient deployment processes.