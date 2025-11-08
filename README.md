# 1. Create K3s Cluster on 3 VMs
    1. Update `install-k3s.sh` with the IPs of your 3 nodes.
    2. Run the script:

    ```bash
    ./install-k3s.sh
    ```
    3. Verify cluster creation:
    ```
    export KUBECONFIG=<config path>
    kubectl get nodes
    ```
# Install & Configure ArgoCD
    1. install argocd
    ```
    make install-argocd
    ```
    2. Check that all pods are running:
    ```
    kubectl get pods -n argocd
    ```
    3. Get the admin password:
    ```
    make get-argocd-password
    ```
    4. Expose ArgoCD service temporarily for browser access:
    ```
    kubectl port-forward svc/argocd-server -n argocd 2222:80
    ```
        - Access ArgoCD in your browser: http://localhost:2222
    5. Connect your Git repository in ArgoCD:
        - Go to Settings → Repositories → Connect Repo
                - Connection method: https
                - Type: git
                - Project: default
                - Repository URL: https://github.com/mdp-eg-org/infra-mdp
                - Username: <username>
                - Password: <TOKEN>

# Install the base-app bootstrap application (cert-manager, longhorn, traefik, longhorn,..):
    ```
    make install-base-app-bootstrap
    ```
    - Verify from Argocd UI that all base-apps installed in cluster

# Install the centralized-app bootstrap application (vault, harbor):
    ```
    make install-centralized-app-bootstrap
    ```
    - Verify from Argocd UI that all centralized-apps installed in cluster

# Configure Vault
## initialize , join and unseal 
```
kubectl exec -ti vault-0 -n vault -- vault operator init
kubectl exec -ti vault-0 -n vault -- vault operator unseal
kubectl exec -ti vault-1 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-2 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-1 -n vault -- vault operator unseal
kubectl exec -ti vault-2 -n vault -- vault operator unseal
```

## Login and list 
```
kubectl exec -ti vault-0 -- vault login
kubectl exec -ti vault-0 -- vault operator raft list-peers
```

## Enable/Create approle and create policy
```
kubectl exec -ti vault-0 -- vault auth enable approle
```

## Create the required policy (Can be done from UI)
 - Create .hcl file in policies dir with required policy and udate command with the appropriate file name and policy name

```
kubectl cp argocd-centralized-apps/vault/config/policies/admin-policy.hcl vault-0:/vault/file
kubectl exec -ti vault-0 -- vault policy write admin-policy /vault/file/admin-policy.hcl
kubectl exec -ti vault-0 -- vault policy list
```
## AppRole

### Add policy to role
```
kubectl exec -ti vault-0 -- vault write auth/approle/role/admin-role policies=admin-policy secret_id_ttl=0 token_num_uses=0 secret_id_num_uses=0
```

### To Delete role
```
kubectl exec -ti vault-0 -- vault delete auth/approle/role/admin-role
```

### Get role_id and secret_id
```
kubectl exec -ti vault-0 -- vault read auth/approle/role/admin-role/role-id
kubectl exec -ti vault-0 -- vault write -f auth/approle/role/admin-role/secret-id
```
