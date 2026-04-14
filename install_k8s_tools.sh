#!/bin/bash
set -e

echo "===== Installing kubectl ====="
curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

echo "===== Installing Minikube ====="
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

echo "===== Installing Kompose ====="
curl -L https://github.com/kubernetes/kompose/releases/latest/download/kompose-linux-amd64 -o kompose
chmod +x kompose
sudo mv ./kompose /usr/local/bin/kompose

echo "====================================================="
echo " DONE! Safe Kubernetes Tools Installed Successfully."
echo "====================================================="
