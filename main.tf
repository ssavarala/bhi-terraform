provider "aws" {
  region                   = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"] 
}

# IAM Role for Lambda Execution
resource "aws_iam_role" "lambda_role" {
  name = "terraform_aws_lambda_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM Policy for Logging from Lambda
resource "aws_iam_policy" "iam_policy_for_lambda" {
  name        = "aws_iam_policy_for_terraform_aws_lambda_role"
  description = "Policy for Lambda logging to CloudWatch"
  path        = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    }
  ]
}
EOF
}

# IAM Policy for Managing Lambda Functions
resource "aws_iam_policy" "lambda_management_policy" {
  name        = "aws_lambda_management_policy"
  description = "Policy to allow Lambda function management"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:CreateFunction",
        "lambda:UpdateFunctionCode",
        "lambda:UpdateFunctionConfiguration",
        "lambda:GetFunction",
        "lambda:DeleteFunction",
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:lambda:*:*:function:*",
        "${aws_iam_role.lambda_role.arn}"
      ]
    }
  ]
}
EOF
}

# Attach Logging Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "attach_logging_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

# Attach Lambda Management Policy to Lambda Role
resource "aws_iam_role_policy_attachment" "attach_lambda_management_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_management_policy.arn
}

data "archive_file" "zip_the_python_code" {
 type        = "zip"
 source_dir  = "${path.module}/python/"
 output_path = "${path.module}/python/hello-python.zip"
}

# Lambda Function
resource "aws_lambda_function" "python_lambda" {
  function_name = "python_lambda_function"
  role          = aws_iam_role.lambda_role.arn
  handler       = "example.lambda_handler"
  runtime       = "python3.9"
  timeout       = 15
  memory_size   = 128
  filename      = "${path.module}/hello-python.zip"
}

# S3 Bucket Creation
resource "aws_s3_bucket" "test_bucket" {
  bucket = "stest-bucket-s3" # Must be globally unique
  tags = {
    Name        = "stest-bucket-s3"
    Environment = "Development"
  }
}

# IAM Policy for S3 Access
resource "aws_iam_policy" "lambda_s3_policy" {
  name        = "aws_lambda_s3_policy"
  description = "Policy to allow Lambda function access to S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = [
          aws_s3_bucket.test_bucket.arn,
          "${aws_s3_bucket.test_bucket.arn}/*"
        ]
      }
    ]
  })
}

# Outputs
output "terraform_aws_role_name" {
  value = aws_iam_role.lambda_role.name
}

output "terraform_aws_role_arn" {
  value = aws_iam_role.lambda_role.arn
}

output "terraform_logging_policy_arn" {
  value = aws_iam_policy.iam_policy_for_lambda.arn
}

output "terraform_lambda_function_name" {
  value = aws_lambda_function.python_lambda.function_name
}

# Outputs
output "s3_bucket_name" {
  value = aws_s3_bucket.test_bucket.bucket
}

