#!/bin/bash

set -e

CLUSTER_NAME="superset-cluster"
NAMESPACE="superset"
RELEASE_NAME="superset"
PORT=8088

# Install Helm if missing
install_helm() {
  echo "📦 Helm not found. Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "✅ Helm installed: $(helm version --short)"
}

echo "🔍 Checking prerequisites..."

# Check tools
command -v kubectl &>/dev/null || { echo "❌ kubectl not found. Aborting."; exit 1; }
command -v kind &>/dev/null || { echo "❌ kind not found. Aborting."; exit 1; }
command -v helm &>/dev/null || install_helm

# Cleanup existing KinD cluster
if kind get clusters | grep -q "$CLUSTER_NAME"; then
  echo "⚠️ KinD cluster '$CLUSTER_NAME' already exists. Deleting it..."
  kind delete cluster --name "$CLUSTER_NAME"
fi

# Create new KinD cluster
echo "🚀 Creating new KinD cluster '$CLUSTER_NAME'..."
kind create cluster --name "$CLUSTER_NAME"

# Cleanup existing Helm release
if helm list -n "$NAMESPACE" | grep -q "$RELEASE_NAME"; then
  echo "⚠️ Helm release '$RELEASE_NAME' already exists. Uninstalling..."
  helm uninstall "$RELEASE_NAME" -n "$NAMESPACE"
fi

# Delete namespace if it exists
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
  echo "⚠️ Namespace '$NAMESPACE' already exists. Deleting..."
  kubectl delete namespace "$NAMESPACE"
  # Wait for namespace to fully terminate
  while kubectl get namespace "$NAMESPACE" &>/dev/null; do
    echo "⏳ Waiting for namespace '$NAMESPACE' to terminate..."
    sleep 3
  done
fi

# Add Bitnami Helm repo
echo "📦 Adding Bitnami Helm chart repo..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create namespace
echo "📂 Creating namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE"

# Install Superset
echo "📥 Installing Apache Superset..."
helm install "$RELEASE_NAME" bitnami/superset --namespace "$NAMESPACE"

# Wait for Superset to be ready
echo "⏳ Waiting for Superset pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=superset -n "$NAMESPACE" --timeout=300s

# Port forward
echo "🌐 Access Superset at: http://localhost:$PORT"
kubectl port-forward svc/"$RELEASE_NAME" $PORT:8088 -n "$NAMESPACE"
