# Create cluster in 3 VMS using scripts install-k3s.sh 
    1. update script to add 3 node IPs
    2. run script
    3. confirm cluster creation by setting context and get nodes
    ```
    export KUBECONFIG=<config path>
    kubectl get nodes
    ```
# Install/Configre Argocd in cluster 
    1. install argocd
    ```
    make install-argocd
    ```
    2. Confirm running 
    ```
    kubectl get pods -n argocd
    ```
    3. get admin password
    ```
    make get-argocd-password
    ```
    4. Expose service to login from browser until creating its ingress
    ```
    kubectl port-forward svc/argocd-server -n argocd 2222:80
    From browser: http://localhost:2222
    ```
    5. Configure argocd access with repo and cluster
        - In argocd settings:
            1. Repositories -> Connect Repo
                - Connection method: https
                - Type: git
                - Project: default
                - Repository URL: https://github.com/mdp-eg-org/infra-mdp
                - Username: <username>
                - Password: <TOKEN>

    6. Install bootstrap app
    ```
    make install-bootstrap
    ```
