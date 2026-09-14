# SentinelOne Agent Deployment

## Overview
SentinelOne agent deployed as a centralized application on the POC cluster.

## Helm Chart
- **Repository**: https://sentinel-one.github.io/helm-charts/
- **Chart**: s1-agent
- **Version**: 26.2.1

## Configuration

### Cluster Name
Set in `values.yaml`:
```yaml
configuration:
  cluster:
    name: "poc-cluster"
```

### Secrets (Vault)

#### 1. SentinelOne Site Key
Path: `prod/sentinelone`

Required keys:
```json
{
  "SITE_KEY": "your-sentinelone-site-key-here"
}
```

#### 2. Docker Registry Credentials
Path: `prod/sentinelone-docker`

Required keys:
```json
{
  "DOCKER_REGISTRY": "registry-url",
  "DOCKER_USERNAME": "username",
  "DOCKER_PASSWORD": "password"
}
```

## Vault Setup

Add secrets to Vault:

```bash
# Add SentinelOne site key
vault kv put prod/sentinelone \
  SITE_KEY="your-site-key-here"

# Add Docker registry credentials
vault kv put prod/sentinelone-docker \
  DOCKER_REGISTRY="registry.sentinelone.net" \
  DOCKER_USERNAME="your-username" \
  DOCKER_PASSWORD="your-password"
```

## Deployment

The application is managed by ArgoCD and will be automatically deployed when:
1. Secrets are configured in Vault
2. The application manifest is applied to ArgoCD

## Monitoring

Check deployment status:
```bash
kubectl get pods -n sentinelone
kubectl get externalsecret -n sentinelone
```

## Troubleshooting

If pods are not starting:
1. Check if secrets are synced: `kubectl get secret -n sentinelone`
2. Check external secret status: `kubectl describe externalsecret -n sentinelone`
3. Verify Vault paths and keys are correct
