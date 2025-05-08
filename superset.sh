#!/bin/bash

set -e

NAMESPACE="superset"
RELEASE_NAME="superset"
PORT=8088

# Function to install Helm if not present
install_helm() {
  echo "📦 Helm not found. Installing Helm..."
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  echo "✅ Helm installed: $(helm version --short)"
}

# Check for prerequisites
echo "🔍 Checking tools..."
command -v kubectl &>/dev/null || { echo "❌ kubectl is not installed. Aborting."; exit 1; }
command -v helm &>/dev/null || install_helm

# Check cluster access
echo "🔗 Checking cluster access..."
kubectl cluster-info || { echo "❌ Unable to connect to the Kubernetes cluster. Aborting."; exit 1; }

# Add Bitnami repo
echo "📦 Adding Bitnami Helm repository..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Create namespace
echo "📂 Creating namespace '$NAMESPACE'..."
kubectl create namespace "$NAMESPACE" || echo "Namespace already exists."

# Install Superset
echo "📥 Installing Apache Superset..."
helm install "$RELEASE_NAME" bitnami/superset --namespace "$NAMESPACE"

# Wait for pods to be ready
echo "⏳ Waiting for Superset pod to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=superset -n "$NAMESPACE" --timeout=300s

# Port-forward
echo "🌐 Access Superset at: http://localhost:$PORT"
kubectl port-forward svc/"$RELEASE_NAME" $PORT:8088 -n "$NAMESPACE"
