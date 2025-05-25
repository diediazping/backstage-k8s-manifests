#!/bin/bash
set -e

echo "🚀 Setting up Backstage with ArgoCD..."

# Variables
NAMESPACE="backstage"
ARGOCD_NAMESPACE="argocd"

# Check if ArgoCD is running
if ! kubectl get namespace $ARGOCD_NAMESPACE >/dev/null 2>&1; then
    echo "❌ ArgoCD namespace not found. Please make sure ArgoCD is installed."
    exit 1
fi

echo "✅ ArgoCD found, proceeding with Backstage setup..."

# Create namespace first
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Get service account token for Kubernetes plugin
echo "🔑 Creating service account and getting token..."
kubectl apply -f manifests/base/rbac.yaml
sleep 5
SA_TOKEN=$(kubectl create token backstage -n $NAMESPACE --duration=8760h 2>/dev/null || echo "")

# Create backstage secrets with real values
echo "🔐 Creating secrets..."
kubectl create secret generic backstage-secrets \
  --from-literal=GITHUB_TOKEN=$yourgithubtoken \
  --from-literal=AUTH_GITHUB_CLIENT_ID=$yourgithubclientid \
  --from-literal=AUTH_GITHUB_CLIENT_SECRET=$yourgithubclientsecret \
  --from-literal=K8S_SERVICE_ACCOUNT_TOKEN="$SA_TOKEN" \
  --from-literal=ARGOCD_TOKEN=$yourargocdtoken \
  -n $NAMESPACE \
  --dry-run=client -o yaml | kubectl apply -f -

# Apply ArgoCD Application
echo "📱 Creating ArgoCD Application..."
kubectl apply -f argocd/backstage-app.yaml

echo "✅ Setup complete!"
echo "🌐 ArgoCD will now sync Backstage automatically"
echo "📊 Check ArgoCD UI to monitor the deployment"

# Get ArgoCD admin password
echo "🔑 ArgoCD admin password:"
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d && echo
