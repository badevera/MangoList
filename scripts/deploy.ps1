<#
.SYNOPSIS
  Deploy Mango List: Terraform apply + Docker build/push + restart app on EC2.

.EXAMPLE
  .\scripts\deploy.ps1
  .\scripts\deploy.ps1 -SkipApply
  .\scripts\deploy.ps1 -Destroy
  .\scripts\deploy.ps1 -AwsProfile mango-terraform
#>
[CmdletBinding()]
param(
  [string] $AwsProfile = "mango-terraform",
  [string] $ImageTag = "latest",
  [switch] $SkipApply,
  [switch] $Destroy,
  [switch] $AutoApprove
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Write-Step([string] $Message) {
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Write-Ok([string] $Message) {
  Write-Host "    $Message" -ForegroundColor Green
}

function Require-Command([string] $Name) {
  if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
    throw "Required command not found: $Name"
  }
}

function Invoke-Checked([scriptblock] $Block, [string] $FailureMessage) {
  & $Block
  if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {
    throw $FailureMessage
  }
}

function Get-AwsRegionFromTfvars([string] $Path) {
  foreach ($line in Get-Content $Path) {
    if ($line -match 'aws_region\s*=\s*"(?<region>[^"]+)"') {
      return $Matches["region"]
    }
  }
  return $null
}

$env:AWS_PROFILE = $AwsProfile

Write-Step "Checking prerequisites"
Require-Command terraform
Require-Command aws
Require-Command docker
Invoke-Checked { aws sts get-caller-identity | Out-Null } "AWS credentials failed for profile '$AwsProfile'."
Invoke-Checked { docker info | Out-Null } "Docker Desktop does not appear to be running."
Write-Ok "AWS profile: $AwsProfile"
Write-Ok "Docker is running"

$Tfvars = Join-Path $Root "terraform\terraform.tfvars"
$TfvarsExample = Join-Path $Root "terraform\terraform.tfvars.example"
if (-not (Test-Path $Tfvars)) {
  if (-not (Test-Path $TfvarsExample)) {
    throw "Missing terraform/terraform.tfvars and terraform.tfvars.example"
  }
  Copy-Item $TfvarsExample $Tfvars
  Write-Ok "Created terraform/terraform.tfvars from example - edit allowed_app_cidr/origin before sharing publicly."
}

$approveArgs = @()
if ($AutoApprove) { $approveArgs = @("-auto-approve") }

if ($Destroy) {
  Write-Step "Destroying infrastructure"
  Invoke-Checked {
    terraform -chdir=terraform destroy @approveArgs
  } "terraform destroy failed."
  Write-Ok "Destroy complete."
  return
}

Write-Step "Initializing Terraform"
Invoke-Checked { terraform -chdir=terraform init -input=false | Out-Host } "terraform init failed."
Invoke-Checked { terraform -chdir=terraform validate | Out-Host } "terraform validate failed."

if (-not $SkipApply) {
  Write-Step "Applying Terraform"
  Invoke-Checked {
    terraform -chdir=terraform apply @approveArgs
  } "terraform apply failed."
  Write-Ok "Infrastructure is up."
} else {
  Write-Ok "Skipping terraform apply (-SkipApply)."
}

Write-Step "Reading Terraform outputs"
$AwsRegion = aws configure get region --profile $AwsProfile
if (-not $AwsRegion) {
  $AwsRegion = Get-AwsRegionFromTfvars $Tfvars
}
if (-not $AwsRegion) {
  $AwsRegion = "us-east-2"
}

$RepositoryUrl = terraform -chdir=terraform output -raw ecr_repository_url
$InstanceId = terraform -chdir=terraform output -raw instance_id
$AppUrl = terraform -chdir=terraform output -raw app_url
$PublicIp = terraform -chdir=terraform output -raw public_ip
$Registry = $RepositoryUrl.Split("/")[0]
$Image = "${RepositoryUrl}:${ImageTag}"
Write-Ok "Region: $AwsRegion"
Write-Ok "ECR: $RepositoryUrl"
Write-Ok "Instance: $InstanceId"
Write-Ok "App URL: $AppUrl"
Write-Ok "Elastic IP: $PublicIp"

Write-Step "Logging in to ECR"
# PowerShell corrupts the password pipe; use cmd for login.
cmd /c "aws ecr get-login-password --region $AwsRegion --profile $AwsProfile | docker login --username AWS --password-stdin $Registry"
if ($LASTEXITCODE -ne 0) { throw "ECR docker login failed." }
Write-Ok "Login succeeded"

Write-Step "Building image $Image"
$Dockerfile = Join-Path $Root "docker\Dockerfile"
Invoke-Checked { docker build -f $Dockerfile -t $Image $Root } "docker build failed."
Write-Ok "Build complete"

Write-Step "Pushing image"
Invoke-Checked { docker push $Image } "docker push failed."
Write-Ok "Push complete"

Write-Step "Restarting app on EC2 (SSM)"
# Use single-quoted strings so PowerShell does not rewrite $, |, or nested quotes.
$commands = @(
  'set -euo pipefail',
  'mkdir -p /usr/local/lib/docker/cli-plugins',
  'if ! docker compose version >/dev/null 2>&1; then curl -sL https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose && chmod +x /usr/local/lib/docker/cli-plugins/docker-compose; fi',
  'cd /opt/mango-list',
  'grep -q sslmode= .env || sed -i "s|^DATABASE_URL=\(.*\)$|DATABASE_URL=\1?sslmode=require|" .env',
  "aws ecr get-login-password --region $AwsRegion | docker login --username AWS --password-stdin $Registry",
  'docker compose pull',
  'docker compose up -d',
  'docker compose ps'
)
$paramsPath = Join-Path $env:TEMP "mango-deploy-ssm.json"
$paramsJson = @{ commands = @($commands) } | ConvertTo-Json -Compress -Depth 5
[System.IO.File]::WriteAllText($paramsPath, $paramsJson)

$CommandId = aws ssm send-command `
  --instance-ids $InstanceId `
  --document-name "AWS-RunShellScript" `
  --parameters "file://$paramsPath" `
  --output text `
  --query "Command.CommandId"
if (-not $CommandId) { throw "Failed to send SSM command." }
Write-Ok "SSM command: $CommandId"

$deadline = (Get-Date).AddMinutes(5)
do {
  Start-Sleep -Seconds 5
  $status = aws ssm get-command-invocation `
    --command-id $CommandId `
    --instance-id $InstanceId `
    --query "Status" `
    --output text
  Write-Host "    SSM status: $status"
} while ($status -in @("Pending", "InProgress", "Delayed") -and (Get-Date) -lt $deadline)

if ($status -ne "Success") {
  $err = aws ssm get-command-invocation `
    --command-id $CommandId `
    --instance-id $InstanceId `
    --query "StandardErrorContent" `
    --output text
  throw "SSM restart failed ($status). $err"
}
Write-Ok "App container restarted"

Write-Host ""
Write-Host "Deploy complete." -ForegroundColor Green
Write-Host "  App:        $AppUrl"
Write-Host "  Elastic IP: $PublicIp"
Write-Host "  Image:      $Image"
Write-Host "  Instance:   $InstanceId"
Write-Host ""
Write-Host "app_url comes from terraform.tfvars origin (not an ephemeral IP)."
Write-Host "Tear down later with:  .\scripts\deploy.ps1 -Destroy -AutoApprove"
