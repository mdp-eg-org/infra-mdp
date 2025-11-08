# Install Vault on Kubernetes
https://developer.hashicorp.com/vault/docs/platform/k8s/helm/configuration

helm repo add hashicorp https://helm.releases.hashicorp.com
helm search repo hashicorp/vault

# Install
```shell
helm install vault hashicorp/vault \
  --namdppace=vault -f values.yaml  \
  --version 0.31.0 \
  --create-namdppace
```
# Upgrade
```shell
helm upgrade vault \
  --namdppace vault \
  -f values.yaml \
  hashicorp/vault \
  --version 0.31.0
```
# Uninstall
```shell 
helm uninstall vault -n vault
```
# initialize , join and unseal 
kubectl exec -ti vault-0 -n vault -- vault operator init
kubectl exec -ti vault-0 -n vault -- vault operator unseal
kubectl exec -ti vault-1 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-2 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-1 -n vault -- vault operator unseal
kubectl exec -ti vault-2 -n vault -- vault operator unseal

# Login and list 
kubectl exec -ti vault-0 -- vault login
kubectl exec -ti vault-0 -- vault operator raft list-peers

# Enable/Create approle and create policy
kubectl exec -ti vault-0 -- vault auth enable approle

# Create the required policy (Can be done from UI)
# Create .hcl file in policies dir with required policy and udate command with the appropriate file name and policy name
kubectl cp policies/admin-policy.hcl vault-0:/vault/file
kubectl exec -ti vault-0 -- vault policy write admin-policy /vault/file/admin-policy.hcl
kubectl exec -ti vault-0 -- vault policy list

# AppRole

## Add policy to role
kubectl exec -ti vault-0 -- vault write auth/approle/role/admin-role policies=admin-policy secret_id_ttl=0 token_num_uses=0 secret_id_num_uses=0

## To Delete role
kubectl exec -ti vault-0 -- vault delete auth/approle/role/admin-role

## Get role_id and secret_id
kubectl exec -ti vault-0 -- vault read auth/approle/role/admin-role/role-id
kubectl exec -ti vault-0 -- vault write -f auth/approle/role/admin-role/secret-id
