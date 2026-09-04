# MDP Website - Kubernetes Deployment

## Architecture

- **Application**: PHP 8.2 with Apache (mdp-website container)
- **Database**: PostgreSQL (existing cluster database)
- **Secrets**: Managed via Vault + External Secrets Operator

## Directory Structure

```
mdp-website/
├── base/
│   ├── deployment.yaml          # App deployment
│   ├── service.yaml             # App service
│   ├── ingress.yaml             # Base ingress config
│   └── kustomization.yaml
└── overlay/
    └── dev/
        ├── kustomization.yaml
        ├── external-secret.yaml
        ├── mdp-website.env      # Non-sensitive config
        └── ingress-patch.yaml
```

## Vault Secret Configuration

### Dev Environment
Path: `dev/mdp-website`

Required keys:
```json
{
  "DB_NAME": "mdp_website",
  "DB_USER": "mdp_website_user",
  "DB_PASS": "your-secure-password"
}
```

## Environment Variables

### From ConfigMap (non-sensitive):
- `DB_HOST` - PostgreSQL service name (default: `postgres.default.svc.cluster.local`)
- `DB_PORT` - PostgreSQL port (default: `5432`)
- `BASE_URL` - Application base URL

### From Vault (sensitive):
- `DB_NAME` - Database name
- `DB_USER` - Database username
- `DB_PASS` - Database password

## Deployment

The deployment is automated via GitHub Actions:

1. Push to `develop` branch triggers dev deployment
2. Manual trigger via workflow_dispatch also available
3. Pipeline builds Docker image and updates Kustomize overlay
4. ArgoCD syncs the changes to the cluster

## Database Initialization

On first deployment, you need to:

1. Create the database in the existing PostgreSQL cluster:
```bash
# Connect to PostgreSQL pod
kubectl exec -it -n default deployment/postgres -- psql -U postgres

# Create database and user
CREATE DATABASE mdp_website;
CREATE USER mdp_website_user WITH ENCRYPTED PASSWORD 'your-password';
GRANT ALL PRIVILEGES ON DATABASE mdp_website TO mdp_website_user;
\q
```

2. Import the database schema (convert MySQL schema to PostgreSQL if needed)
3. Seed initial data

## Accessing the Application

- **Dev**: https://website.poc.mdplabs.dev

## Scaling

Replicas are configured in overlay kustomization.yaml:
- Dev: 1 replica

## Monitoring

Resource requests/limits:
- **App**: 256Mi-512Mi memory, 100m-500m CPU
