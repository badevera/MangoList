data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_ecr_repository" "app" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_iam_role" "app" {
  name = "${var.project_name}-ec2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "app" {
  role = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:BatchCheckLayerAvailability", "ecr:BatchGetImage", "ecr:GetDownloadUrlForLayer"]
        Resource = aws_ecr_repository.app.arn
      },
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = aws_secretsmanager_secret.database.arn
      }
    ]
  })
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.project_name}-ec2"
  role = aws_iam_role.app.name
}

resource "aws_eip" "app" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-app"
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = true

  user_data = <<-USERDATA
    #!/bin/bash
    set -euo pipefail

    dnf install -y docker jq
    systemctl enable --now docker
    mkdir -p /opt/mango-list

    aws secretsmanager get-secret-value \
      --secret-id '${aws_secretsmanager_secret.database.arn}' \
      --query SecretString \
      --output text > /opt/mango-list/database.json

    db_host='${aws_db_instance.database.address}'
    db_user=$(jq -r '.username' /opt/mango-list/database.json)
    db_password=$(jq -r '.password' /opt/mango-list/database.json)
    db_name=$(jq -r '.database' /opt/mango-list/database.json)

    printf 'APP_IMAGE=%s\nDATABASE_URL=postgresql://%s:%s@%s:5432/%s?sslmode=require\nORIGIN=%s\n' \
      '${aws_ecr_repository.app.repository_url}:${var.image_tag}' "$${db_user}" "$${db_password}" "$${db_host}" "$${db_name}" '${var.origin}' \
      > /opt/mango-list/.env

    cat > /opt/mango-list/docker-compose.yml <<'EOF'
    services:
      app:
        image: $${APP_IMAGE}
        restart: unless-stopped
        env_file:
          - .env
        ports:
          - "3000:3000"
        command: sh -c "npx drizzle-kit migrate && node build"
        healthcheck:
          test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:3000/api/health').then((r) => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"]
          interval: 30s
          timeout: 5s
          retries: 3
          start_period: 20s
    EOF

    aws ecr get-login-password --region '${var.aws_region}' | docker login --username AWS --password-stdin '${aws_ecr_repository.app.repository_url}'
    docker compose -f /opt/mango-list/docker-compose.yml up -d
  USERDATA

  depends_on = [
    aws_secretsmanager_secret_version.database
  ]
}

resource "aws_eip_association" "app" {
  instance_id   = aws_instance.app.id
  allocation_id = aws_eip.app.id
}
