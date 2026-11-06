# Mango List

A grocery list app built with SvelteKit, TypeScript, Tailwind CSS, daisyUI, PostgreSQL, and Drizzle ORM.

Sign in with a username (no password), create lists, and check off items. Data is stored in PostgreSQL.

## Getting started (local)

```bash
npm install
cp .env.example .env   # if needed
npm run db:up
npm run db:generate
npm run db:migrate
npm run dev
```

Open [http://localhost:5173](http://localhost:5173).

### Local database

Docker Compose runs PostgreSQL (`mango_list` / `mango_app` / `local_password` on port `5432`):

```env
DATABASE_URL=postgresql://mango_app:local_password@localhost:5432/mango_list
```

- `npm run db:down` — stop Postgres (keeps data)
- `docker compose down -v` — wipe local DB volumes

## Scripts

| Command | Purpose |
|---------|---------|
| `npm run dev` | Dev server |
| `npm run check` | Svelte / TypeScript checks |
| `npm run build` | Production build |
| `npm run db:up` / `db:down` | Start / stop local Postgres |
| `npm run db:generate` | Generate Drizzle migrations |
| `npm run db:migrate` | Apply migrations |
| `.\deploy.ps1` | AWS deploy (Terraform + Docker + EC2 restart) |

## Health checks

- `GET /api/health` — JSON status for the app and PostgreSQL (`200` healthy, `503` unhealthy)
- `/health` — same checks in a browser-friendly page

## Architecture (AWS)

### Request path (browser → app → database → browser)

How a typical page or form request moves through the stack and back:

```mermaid
sequenceDiagram
  actor Browser
  participant DNS as DuckDNS / DNS
  participant EIP as Elastic IP
  participant SG as Security Group
  participant Nginx as Nginx on EC2
  participant App as SvelteKit container
  participant RDS as RDS PostgreSQL

  Browser->>DNS: Resolve mangolist.duckdns.org
  DNS-->>Browser: Elastic IP
  Browser->>EIP: HTTPS :443 (or :3000)
  EIP->>SG: Forward to EC2 ENI
  SG->>Nginx: Allow if CIDR matches
  Nginx->>App: Proxy to localhost:3000
  App->>RDS: SQL over VPC (sslmode=require)
  RDS-->>App: Query result
  App-->>Nginx: HTML / JSON response
  Nginx-->>Browser: Response via Elastic IP
```

```mermaid
flowchart LR
  subgraph Internet
    B[Browser]
    DNS[DuckDNS]
  end

  subgraph AWS["AWS account / us-east-2"]
    subgraph VPC["VPC"]
      subgraph Public["Public subnet"]
        EIP[Elastic IP]
        SG[App security group]
        EC2["EC2: Nginx + Docker Compose"]
        APP["SvelteKit app container :3000"]
      end
      subgraph Private["Private subnet"]
        RDS[(RDS PostgreSQL)]
      end
    end
    ECR[ECR image repo]
    SM[Secrets Manager]
    IAM[IAM instance profile]
  end

  B -->|1. DNS lookup| DNS
  DNS -->|2. Returns EIP| B
  B -->|3. HTTPS request| EIP
  EIP --> SG
  SG --> EC2
  EC2 --> APP
  APP -->|4. SQL| RDS
  RDS -->|5. Rows| APP
  APP -->|6. Response| B
  ECR -.->|image pull at deploy/boot| EC2
  SM -.->|DB secret at boot| EC2
  IAM -.->|SSM / ECR / secrets| EC2
```

### AWS services in this design

| Service | Role in a request or deploy |
|---------|-----------------------------|
| **Route to host** | DuckDNS (external) → **Elastic IP** on the EC2 ENI |
| **VPC / subnets** | Public subnet for EC2; private subnets for RDS |
| **Security groups** | Ingress 80/443/3000 to the app; Postgres **only** from the app SG |
| **EC2** | Runs Nginx (HTTPS) and the Dockerized SvelteKit app |
| **ECR** | Stores the app image (pulled at deploy / boot, not on every page request) |
| **RDS PostgreSQL** | Durable lists/items; app connects with `sslmode=require` |
| **Secrets Manager** | Holds the generated DB password (read at instance bootstrap) |
| **IAM instance profile** | Lets EC2 use SSM, pull from ECR, and read the secret |

Terraform under `terraform/` creates the VPC, EC2, Elastic IP, RDS, ECR, security groups, IAM profile, and secret. `deploy.ps1` applies Terraform, builds/pushes the image to ECR, and restarts the container over SSM.

`ORIGIN` in `terraform.tfvars` must match the URL users open (for example `https://mangolist.duckdns.org`). SvelteKit form actions fail with CSRF/`403` if it does not.

Optional (configured on the instance, not in Terraform): DuckDNS hostname + Nginx + Let’s Encrypt for HTTPS.

## Deploying to AWS

**Prerequisites:** Terraform 1.6+, Docker Desktop, AWS CLI profile with permission to create the stack (not an ECR-only user).

1. Copy and edit vars:

```powershell
copy terraform\terraform.tfvars.example terraform\terraform.tfvars
```

Set `allowed_app_cidr`, `origin`, region, and AZs.

2. Deploy everything from the repo root:

```powershell
.\deploy.ps1 -AwsProfile mango-terraform -AutoApprove
```

This runs Terraform apply, builds/pushes the Docker image to ECR, and restarts the app on EC2 via SSM.

| Flag | Meaning |
|------|---------|
| `-SkipApply` | Rebuild/push image and restart only |
| `-Destroy` | Tear down AWS resources |
| `-AutoApprove` | No interactive Terraform confirm |
| `-AwsProfile` | AWS CLI profile (default `mango-terraform`) |

3. Open the URL from Terraform:

```powershell
terraform -chdir=terraform output app_url
terraform -chdir=terraform output public_ip
```

Use `app_url` (from `origin`), not an old ephemeral IP. Point DuckDNS at `public_ip` if you use a free subdomain.

### Cleanup

```powershell
.\deploy.ps1 -Destroy -AutoApprove
```

Do not commit `terraform.tfvars`, Terraform state, or AWS keys. More detail: [terraform/README.md](terraform/README.md).
