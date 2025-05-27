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
  --from-literal=GITHUB_TOKEN='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' \
  --from-literal=AUTH_GITHUB_CLIENT_ID='Ov23li8UQEjN0or60bp4' \
  --from-literal=AUTH_GITHUB_CLIENT_SECRET='20730cb7f7bab15f3a2a1c718327c1cc76ea063d' \
  --from-literal=K8S_SERVICE_ACCOUNT_TOKEN="$SA_TOKEN" \
  --from-literal=ARGOCD_TOKEN='argocd.token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJhcmdvY2QiLCJzdWIiOiJhZG1pbjphcGlLZXkiLCJuYmYiOjE3NDc2OTE0NzksImlhdCI6MTc0NzY5MTQ3OSwianRpIjoiYjIxNWExNDctMzE2ZC00ZTVmLWE1ZmYtMjQ2NDE4NDdkYjM4In0.6pfRzgGWpJqC9oojROyVqo2NdlsXWpUpt1ECBU8jM_o' \
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
