# Install Vault on Kubernetes
https://developer.hashicorp.com/vault/docs/platform/k8s/helm/configuration

helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/vault

# Install
```shell
helm install vault-dev hashicorp/vault \
  --namespace=vault-dev -f values.yaml  \
  --version 0.31.0 \
  --create-namespace
```
# Upgrade
```shell
helm upgrade vault-dev \
  --namespace vault-dev \
  -f values.yaml \
  hashicorp/vault \
  --version 0.31.0
```
# Uninstall
```shell 
helm uninstall vault-dev -n vault-dev
```
# initialize , join and unseal 
kubectl exec -ti vault-dev-0 -n vault-dev -- vault operator init
kubectl exec -ti vault-dev-0 -n vault-dev -- vault operator unseal
kubectl exec -ti vault-dev-1 -n vault-dev -- vault operator raft join http://vault-dev-0.vault-dev-internal:8200
kubectl exec -ti vault-dev-2 -n vault-dev -- vault operator raft join http://vault-dev-0.vault-dev-internal:8200
kubectl exec -ti vault-dev-1 -n vault-dev -- vault operator unseal
kubectl exec -ti vault-dev-2 -n vault-dev -- vault operator unseal

# Login and list 
kubectl exec -ti vault-dev-0 -- vault login
kubectl exec -ti vault-dev-0 -- vault operator raft list-peers

# Configure ldap
  1. kubectl exec -ti vault-dev-0 -n vault-dev  --  vault auth enable ldap
  2. export LDAPPASSWORD='<PASSWORD>'
	2. kubectl exec -ti vault-dev-0 -n vault-dev  --  vault write auth/ldap/config \
    url="ldaps://sgc4dc03.aptargroup.loc"  \
    binddn="sa-bindgrafana@aptargroup.loc" \
    bindpass=$LDAPPASSWORD \
    userdn="DC=aptargroup,DC=loc" \
    groupdn="DC=aptargroup,DC=loc" \
    groupfilter="(&(objectClass=group)(|(cn=SEC-GG-GLO-IS-MES-ARGOCD-ADMIN)(cn=ADG-GG-GLO-VM-SecDevOps))(member={{.UserDN}}))" \
    userattr="cn"  userfilter="(cn={{.Username}})" \
    starttls=false \
    use_ssl=false \
    insecure_tls=true \
    groupattr="memberof" 

# Enable/Create approle and create policy
kubectl exec -ti vault-dev-0 -- vault auth enable approle

# Create the required policy (Can be done from UI)
# Create .hcl file in policies dir with required policy and udate command with the appropriate file name and policy name
kubectl cp policies/admin-policy.hcl vault-dev-0:/vault/file
kubectl cp policies/mes-policy.hcl vault-dev-0:/vault/file
kubectl exec -ti vault-dev-0 -- vault policy write admin-policy /vault/file/admin-policy.hcl
kubectl exec -ti vault-dev-0 -- vault policy write mes-policy /vault/file/mes-policy.hcl
kubectl exec -ti vault-dev-0 -- vault policy list

# Add policy to ldap group
kubectl exec -ti vault-dev-0 -- vault write  auth/ldap/groups/ADG-GG-GLO-Devops-SuperAdmin policies=admin-policy
kubectl exec -ti vault-dev-0 -- vault write  auth/ldap/groups/ADG-GG-GLO-VM-SecDevOps policies=admin-policy

# AppRole

## Add policy to role
kubectl exec -ti vault-dev-0 -- vault write auth/approle/role/mes-role policies=mes-policy secret_id_ttl=0 token_num_uses=0 secret_id_num_uses=0

## To Delete role
kubectl exec -ti vault-dev-0 -- vault delete auth/approle/role/mes-role

## Get role_id and secret_id
kubectl exec -ti vault-dev-0 -- vault read auth/approle/role/mes-role/role-id
kubectl exec -ti vault-dev-0 -- vault write -f auth/approle/role/mes-role/secret-id

### Then create secret in k8s cluster with secret id

## You will need to install external secrets in clusters to integrate with vault
helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets external-secrets/external-secrets --namespace external-secrets \
    --create-namespace --set installCRDs=true

## Then apply clusterSecretStore in target cluster:

```
vim clustersecretstore

apiVersion: external-secrets.io/v1
kind: ClusterSecretStore
metadata:
  name: mes-vault-store-dev
spec:
  provider:
    vault:
      server: "https://vault.aptar.dev"
      version: "v2"
      path: ./
      auth:
        appRole:
          path: approle
          roleId: <ROLE ID>
          secretRef:
            name: mes-vault-approle-dev
            key: secretId
            namespace: external-secrets
```

## create secret for secretID
``` 
kubectl create secret generic mes-vault-approle-dev -n external-secrets --from-literal=secretId=<SECRET-ID>
kubectl apply -f clustersecretstore
'''