#!/bin/bash

# Configs related to running the control-plane. POD_CIDR is for internal-pod-ips. 
POD_CIDR="10.244.0.0/16"
SERVICE_CIDR="10.96.0.0/12"
APISERVER_IP=$(/usr/bin/ip address show dev enp0s3 | /usr/bin/grep -w inet | /usr/bin/awk '{print $2}' | /usr/bin/cut -d '/' -f 1)
SERVICE_DNS_DOMAIN="cluster.local"

# init kubeadm
sudo kubeadm init --pod-network-cidr ${POD_CIDR} --control-plane-endpoint ${APISERVER_IP} --node-name "$(hostname)" --service-cidr ${SERVICE_CIDR} --service-dns-domain ${SERVICE_DNS_DOMAIN} --apiserver-cert-extra-sans "$(hostname)"

# setup aliases
cat <<EOF >> /home/${SUDO_USER}/.bash_aliases
# set up autocomplete in bash into the current shell, bash-completion package should be installed first.
source <(kubectl completion bash)

alias k=kubectl
complete -o default -F __start_kubectl k
EOF

sudo chown ${SUDO_USER}:${SUDO_USER} /home/${SUDO_USER}/.bash_aliases

# setup kubectl
sudo mkdir -p /home/${SUDO_USER}/.kube
sudo cp -fi /etc/kubernetes/admin.conf /home/${SUDO_USER}/.kube/config
sudo chown -R ${SUDO_USER}:${SUDO_USER} /home/${SUDO_USER}/.kube 

# Add flannel to network, metrics and dns-horizontal-scaler.
sudo kubectl apply -f admin --recursive
