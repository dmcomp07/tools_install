#!/bin/bash

set -e

CLUSTER_NAME="superset-cluster"
NAMESPACE="superset"
RELEASE_NAME="superset"
PORT=8088

# Function to install Helm if missing
install_helm() {
  echo "📦 Helm not found. Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "✅ Helm installed: $(helm version --short)"
}

# Check for Helm, install if missing
if ! command -v helm &> /dev/null; then
  install_helm
else
  echo "✅ Helm already installed: $(helm version --short)"
fi

# Check for kind
if ! command -v kind &> /dev/null; then
  echo "❌ 'kind' not found. Please install KinD first: https://kind.sigs.k8s.io/"
  exit 1
fi

# Check for kubectl
if ! command -v kubectl &> /dev/null; then
  echo "❌ 'kubectl' not found. Please install kubectl first: https://kubernetes.io/docs/tasks/tools/"
  exit 1
fi

# Create KinD cluster
echo "🚀 Creating KinD cluster '$CLUSTER_NAME'..."
kind create cluster --name "$CLUSTER_NAME"

# Add Bitnami repo
echo "📦 Adding Bitnami Helm repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create namespace
echo "📂 Creating namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE" || echo "Namespace already exists"

# Install Superset
echo "📥 Installing Apache Superset in namespace '$NAMESPACE'..."
helm install "$RELEASE_NAME" bitnami/superset --namespace "$NAMESPACE"

# Wait for Superset pod to be ready
echo "⏳ Waiting for Superset pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=superset -n "$NAMESPACE" --timeout=300s

# Port forward to localhost
echo "🌐 Superset will be available at: http://localhost:$PORT"
kubectl port-forward svc/"$RELEASE_NAME" $PORT:8088 -n "$NAMESPACE"
