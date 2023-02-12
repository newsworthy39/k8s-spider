#!/bin/bash

# Configs related to running the control-plane
POD_CIDR="10.244.0.0/16"
APISERVER_IP=$(/usr/bin/ip address show dev enp0s3 | /usr/bin/grep -w inet | /usr/bin/awk '{print $2}' | /usr/bin/cut -d '/' -f 1)

# Debian related workarounds.
[ ! -d /etc/apt/keyrings ] &&  sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# netfilter
sudo modprobe br_netfilter

# Software needed.
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl

# Keyring
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# add to apt repo
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Do a update
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl containerd.io
sudo apt-mark hold kubelet kubeadm kubectl

# ip_forward must be 1
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/20-ipforward.conf 
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Turn of swap
sudo swapoff -a
sudo systemctl enable containerd 
sudo systemctl restart containerd 

# init kubeadm
sudo kubeadm init --pod-network-cidr=${POD_CIDR} --control-plane-endpoint=${APISERVER_IP}

# setup kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Add flannel to network.
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/v0.21.1/Documentation/kube-flannel.yml
