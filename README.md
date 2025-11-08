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