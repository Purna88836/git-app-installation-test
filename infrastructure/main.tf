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