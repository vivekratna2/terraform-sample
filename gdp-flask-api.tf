resource "aws_instance" "flask_api_instance" {
  ami                         = "ami-098e42ae54c764c35"
  associate_public_ip_address = true
  instance_type               = "t3a.small"
  key_name                    = "us-west-2"
  vpc_security_group_ids      = [aws_security_group.api_security_group.id]
  subnet_id                   = var.public_subnet_id
  iam_instance_profile        = aws_iam_instance_profile.flask_api_profile.name
  user_data = templatefile(
    "${path.module}/server-userdata.tpl",
    {
      environment     = terraform.workspace
    }
  )

  tags = {
    Name        = "flask_api_${terraform.workspace}"
    Environment = terraform.workspace
  }
}

resource "aws_iam_instance_profile" "flask_api_profile" {
  name = "flask_api_profile_${terraform.workspace}"
  role = aws_iam_role.flask_api_role.name
}

resource "aws_iam_role" "flask_api_role" {
  name               = "flask_api_role_${terraform.workspace}"
  assume_role_policy = <<EOF
  {
      "Version": "2012-10-17",
      "Statement": [
          {
              "Action": "sts:AssumeRole",
              "Principal": {
                 "Service": "ec2.amazonaws.com"
              },
              "Effect": "Allow",
              "Sid": ""
          }
      ]
  }
  EOF

  inline_policy {
    name = "app_inline_policy_ec2"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ec2:DescribeTags",
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }

  inline_policy {
    name = "app_inline_policy_s3"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "s3:*",
            "secretsmanager:GetRandomPassword",
            "secretsmanager:GetResourcePolicy",
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecretVersionIds",
            "secretsmanager:ListSecrets"
          ]
          Effect   = "Allow"
          Resource = "*"
        }
      ]
    })
  }
}
