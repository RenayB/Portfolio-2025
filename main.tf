provider "aws" {
  region = "us-east-1" # Change this if needed
}

# AWS IAM Role for Amplify
resource "aws_iam_role" "amplify_role" {
  name = "AmplifyAstroDeploymentRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "amplify.amazonaws.com"
      }
    }]
  })
}

# AWS Amplify App
resource "aws_amplify_app" "astro_app" {
  name       = "AstroApp"
  repository = "https://github.com/RenayB/Portfolio-2025"  
  oauth_token = "ghp_YOUR_GITHUB_ACCESS_TOKEN" # Replace with a valid GitHub token

  build_spec = <<EOT
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm install
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: dist
    files:
      - '**/*'
  cache:
    paths:
      - node_modules/**/*
EOT
}

# AWS Amplify Branch (Main)
resource "aws_amplify_branch" "main" {
  app_id      = aws_amplify_app.astro_app.id
  branch_name = "main"
  enable_auto_build = true
}

# Route 53: Get Hosted Zone for renay-brown.com
data "aws_route53_zone" "domain_zone" {
  name = "renay-brown.com"
}

# Route 53: Create a CNAME Record for Amplify
resource "aws_route53_record" "amplify_record" {
  zone_id = data.aws_route53_zone.domain_zone.zone_id
  name    = "www.renay-brown.com"
  type    = "CNAME"
  ttl     = 300
  records = [aws_amplify_app.astro_app.default_domain]
}

# Route 53: Redirect Root Domain to WWW (Using Alias)
resource "aws_route53_record" "root_redirect" {
  zone_id = data.aws_route53_zone.domain_zone.zone_id
  name    = "renay-brown.com"
  type    = "A"
  alias {
    name                   = aws_amplify_app.astro_app.default_domain
    zone_id                = data.aws_route53_zone.domain_zone.zone_id
    evaluate_target_health = false
  }
}
