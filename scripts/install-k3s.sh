#!/bin/bash

# Hetzner servers - just public IPs
masters=(
    "157.90.149.78"
    "167.235.240.112" 
    "91.99.125.137"
)

workers=(
)

# Config
USER=root
kubeconfig="./hetzner-cluster.conf"
k3s_version="v1.33.5+k3s1"
extra_args="--disable traefik --disable servicelb --cluster-init"

install_first_master() {
    echo "Installing first master: $1"
    
    k3sup install \
        --ip $1 \
        --user $USER \
        --cluster \
        --k3s-extra-args "$extra_args" \
        --local-path $kubeconfig \
        --k3s-version $k3s_version
}

join_master() {
    echo "Joining master: $1"
    
    k3sup join \
        --ip $1 \
        --user $USER \
        --server-user $USER \
        --server-ip $MASTER \
        --server \
        --k3s-extra-args "$extra_args" \
        --k3s-version $k3s_version
}

join_worker() {
    echo "Joining worker: $1"
    
    k3sup join \
        --ip $1 \
        --user $USER \
        --server-ip $MASTER \
        --k3s-version $k3s_version
}

install() {
    echo "Setting up HA cluster with ${#masters[@]} masters and ${#workers[@]} workers"
    
    # First master
    install_first_master ${masters[0]}
    MASTER=${masters[0]}
    
    # Additional masters
    for i in $(seq 1 $((${#masters[@]} - 1))); do
        join_master ${masters[i]}
    done
    
    # Workers
    for worker in "${workers[@]}"; do
        join_worker $worker
    done
    
    echo "Cluster ready! Use: export KUBECONFIG=$kubeconfig"
}

add_worker() {
    if [ -z "$1" ]; then
        echo "Usage: $0 add-worker IP"
        exit 1
    fi
    
    MASTER=${masters[0]}
    join_worker $1
    echo "Worker $1 added to cluster"
}

uninstall() {
    for node in "${masters[@]}" "${workers[@]}"; do
        echo "Uninstalling: $node"
        ssh $USER@$node "k3s-uninstall.sh 2>/dev/null || k3s-agent-uninstall.sh" || true
    done
}

# Main
case "${1:-install}" in
    install) install ;;
    uninstall) uninstall ;;
    add-worker) add_worker "$2" ;;
    *) echo "Usage: $0 [install|uninstall|add-worker IP]" ;;
esac

# Usage
# Install the cluster
# ./install-k3s.sh install

# # Add a new worker node
# ./install-k3s.sh add-worker 13.14.15.16

# # Destroy the cluster
# ./install-k3s.sh uninstall