# MDP Website - Kubernetes Deployment

## Architecture

- **Application**: Next.js 16 + Payload 3 (Node 22, `next start` on port 3000).
  Source lives in `site/` of `mdp-eg-org/mdp-website`; the image is built by that
  repo's `.github/workflows/cluster-deploy.yml` on push to `develop`.
- **Database**: PostgreSQL (shared cluster DB `postgres.default.svc.cluster.local:5432`).
  Payload connects via a single `DATABASE_URL`.
- **Media**: Payload stores uploads on local disk (`MEDIA_DIR=/data/media`), backed by
  the `mdp-website-media` PVC (there is no S3/cloud-storage adapter).
- **Secrets**: Vault + External Secrets Operator (`dev/mdp-website`).

## Directory Structure

```
mdp-website/
├── base/
│   ├── deployment.yaml   # Node server, port 3000, media PVC mount, probes
│   ├── service.yaml      # port 80 -> targetPort 3000
│   ├── ingress.yaml      # base ingress
│   ├── pvc.yaml          # mdp-website-media (RWO, longhorn-replica2)
│   └── kustomization.yaml
└── overlay/
    └── dev/
        ├── kustomization.yaml   # image, namespace mdp-website-dev
        ├── external-secret.yaml # pulls dev/mdp-website from Vault
        ├── mdp-website.env      # non-sensitive config (see below)
        └── ingress-patch.yaml   # host website.poc.mdplabs.dev
```

## Vault Secret Configuration (`dev/mdp-website`)

Required keys (each becomes an env var via `envFrom` on the secret):

```json
{
  "DATABASE_URL": "postgresql://mdp_website_user:<password>@postgres.default.svc.cluster.local:5432/mdp_website",
  "PAYLOAD_SECRET": "<random-64-char-string>",
  "PREVIEW_SECRET": "<random-string>"
}
```

Optional (contact-form email; unset = email disabled, submissions still persist):
`SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `CONTACT_NOTIFY_TO`.

> The previous PHP `DB_HOST/DB_PORT/DB_NAME/DB_USER/DB_PASS` keys are not used by
> the Payload app and can be removed once the PHP site is retired.

## Non-sensitive Config (ConfigMap from `mdp-website.env`)

- `NODE_ENV=production`
- `NEXT_PUBLIC_SERVER_URL` / `REVALIDATE_URL` = `https://website.poc.mdplabs.dev`
- `MEDIA_DIR=/data/media`
- `PAYLOAD_DB_PUSH=true` — POC has no committed migrations; Payload pushes the
  schema on boot. Remove once migrations are introduced (see below).

## Database Initialization

Create the database/user once on the shared PostgreSQL instance:

```bash
kubectl exec -it -n default deployment/postgres -- psql -U postgres
CREATE DATABASE mdp_website;
CREATE USER mdp_website_user WITH ENCRYPTED PASSWORD '<password>';
GRANT ALL PRIVILEGES ON DATABASE mdp_website TO mdp_website_user;
\q
```

With `PAYLOAD_DB_PUSH=true`, Payload creates the tables on first boot. Content and
media still need seeding so the site isn't empty (an empty media set can 500
media-dependent pages).

**Before production:** generate Payload migrations (`pnpm payload migrate:create`),
run `pnpm payload migrate` on deploy, and drop `PAYLOAD_DB_PUSH`.

## Deployment

1. Push to `develop` in the app repo triggers the dev build.
2. The pipeline builds/pushes the image to `harbor.poc.mdplabs.dev/mdp-website/website`
   and bumps `newTag` in `overlay/dev/kustomization.yaml`.
3. ArgoCD (`mdp-website` app, namespace `mdp-website-dev`) syncs the change.

## Access

- **Dev**: https://website.poc.mdplabs.dev
