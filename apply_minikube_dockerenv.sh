#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── 1. Point Docker CLI at Minikube's daemon ──────────────────────────────────
echo "==> Pointing Docker CLI to Minikube's Docker daemon..."
eval "$(minikube docker-env)"

# ── 2. Build custom images inside Minikube's Docker ──────────────────────────
echo "==> Building images inside Minikube's Docker..."
docker build -t backend:latest        "$SCRIPT_DIR/backend"
docker build -t transactions:latest   "$SCRIPT_DIR/transactions"
docker build -t studentportfolio:latest "$SCRIPT_DIR/studentportfolio"

# ── 3. Verify images are present ─────────────────────────────────────────────
echo "==> Verifying images inside Minikube's Docker..."
docker images | grep -E "backend|transactions|studentportfolio|nginx"

# ── 4. Apply manifests in dependency order ────────────────────────────────────
# ConfigMaps and Secrets must exist before Deployments that reference them
echo "==> Applying ConfigMaps and Secrets first..."
kubectl apply -f "$SCRIPT_DIR/k8s/nginx-configmap.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/backend-secret.yaml"

echo "==> Applying Services..."
kubectl apply -f "$SCRIPT_DIR/k8s/mongo-service.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/backend-service.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/transactions-service.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/studentportfolio-service.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/nginx-service.yaml"

echo "==> Applying Workloads (StatefulSet + Deployments)..."
kubectl apply -f "$SCRIPT_DIR/k8s/mongo-statefulset.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/backend-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/transactions-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/studentportfolio-deployment.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/nginx-deployment.yaml"

echo "==> Applying HPAs..."
kubectl apply -f "$SCRIPT_DIR/k8s/backend-hpa.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/transactions-hpa.yaml"

# ── 5. Restart deployments to guarantee local images are used ─────────────────
echo "==> Restarting deployments to pick up local images..."
kubectl rollout restart deployment/backend
kubectl rollout restart deployment/transactions
kubectl rollout restart deployment/studentportfolio
kubectl rollout restart deployment/nginx

# ── 6. Wait for all rollouts ──────────────────────────────────────────────────
echo "==> Waiting for rollouts to complete..."
kubectl rollout status deployment/backend        --timeout=120s
kubectl rollout status deployment/transactions   --timeout=120s
kubectl rollout status deployment/studentportfolio --timeout=120s
kubectl rollout status deployment/nginx          --timeout=120s

# ── 7. Show final pod state ───────────────────────────────────────────────────
echo "==> Current pod status:"
kubectl get pods -o wide

# ── 8. Launch via minikube ────────────────────────────────────────────────────
echo "==> Launching application via minikube service..."
minikube service nginx
