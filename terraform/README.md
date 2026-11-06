# Terraform deployment

Provisions the AWS environment for Mango List and pairs with the root `deploy.ps1` script for image publish and EC2 restart.

## What gets created

| Resource | Role |
|----------|------|
| VPC, public/private subnets, IGW, route tables | Network isolation |
| Security groups | App ingress on 3000 / 80 / 443; Postgres only from the app SG |
| EC2 (`t3.micro` by default) | Runs the app with Docker Compose |
| Elastic IP | Stable public IP for DNS (DuckDNS, etc.) |
| RDS PostgreSQL 16 | Private DB; Free Tier–friendly (`backup_retention_period = 0`) |
| ECR | Stores the app container image |
| Secrets Manager | Generated DB credentials |
| IAM instance profile | SSM, ECR pull, secret read |

## Prerequisites

- Terraform **1.6+**
- Docker Desktop
- AWS CLI profile that can create VPC/EC2/RDS/IAM/ECR/Secrets Manager (an ECR-only user is not enough)
- `terraform/terraform.tfvars` (copy from `terraform.tfvars.example`)

Important `tfvars`:

- `origin` — exact public URL browsers use (`https://your.duckdns.org` or `http://ELASTIC_IP:3000`)
- `allowed_app_cidr` — who can reach the app (`YOUR.IP/32` or `0.0.0.0/0`)
- `aws_region` / `availability_zones` — must match (region, not an AZ letter alone)

## Preferred deploy (Windows)

From the **repo root**:

```powershell
.\deploy.ps1 -AwsProfile mango-terraform -AutoApprove
.\deploy.ps1 -SkipApply                 # image rebuild + EC2 restart only
.\deploy.ps1 -Destroy -AutoApprove      # tear down
```

`deploy.ps1` will:

1. `terraform init` / `validate` / `apply` (unless `-SkipApply`)
2. Log in to ECR (via `cmd` — PowerShell piping breaks ECR login on Windows)
3. `docker build` + `docker push`
4. SSM into the instance: ensure Compose plugin, keep `?sslmode=require` on `DATABASE_URL`, pull and restart

## Manual deploy

```bash
terraform -chdir=terraform init
terraform -chdir=terraform validate
terraform -chdir=terraform apply
```

Publish the image (registry host only for `docker login`, not the full repo path):

```bash
REPOSITORY_URL="$(terraform -chdir=terraform output -raw ecr_repository_url)"
REGISTRY="${REPOSITORY_URL%%/*}"
REGION="$(aws configure get region)"

# Windows PowerShell: use cmd for the login pipe
cmd /c "aws ecr get-login-password --region %REGION% | docker login --username AWS --password-stdin %REGISTRY%"

docker build -t "$REPOSITORY_URL:latest" .
docker push "$REPOSITORY_URL:latest"
```

Restart the app if the instance booted before the image existed:

```bash
aws ssm send-command \
  --instance-ids "$(terraform -chdir=terraform output -raw instance_id)" \
  --document-name "AWS-RunShellScript" \
  --parameters commands='["cd /opt/mango-list && docker compose up -d"]'
```

## Outputs

| Output | Meaning |
|--------|---------|
| `app_url` | Value of `origin` — the URL users should open |
| `public_ip` | Elastic IP — point DNS here |
| `instance_id` | EC2 id for SSM |
| `ecr_repository_url` | Image push target |
| `database_endpoint` | Private RDS hostname |
| `database_secret_arn` | Secrets Manager ARN |

## HTTPS / custom hostname (optional, free)

1. Create a DuckDNS name and set its IPv4 to `public_ip`
2. On the instance: Nginx reverse proxy + Certbot (Let’s Encrypt)
3. Set `origin = "https://yourname.duckdns.org"` in `terraform.tfvars` and re-apply / restart the app container so CSRF checks pass

## Cleanup

```powershell
.\deploy.ps1 -Destroy -AutoApprove
```

or `terraform -chdir=terraform destroy`.

Never commit `terraform.tfvars`, `*.tfstate*`, or AWS credentials. Prefer a remote encrypted state backend for shared or production use.
