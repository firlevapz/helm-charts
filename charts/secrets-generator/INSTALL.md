# Installation Guide - secrets-generator

## Prerequisites

- Kubernetes cluster (1.19+)
- Helm 3.x installed
- kubectl configured to access your cluster

## Installation Methods

### Method 1: Install from Local Chart

```bash
# Navigate to the helm-charts directory
cd helm-charts

# Create your values file
cat > my-values.yaml <<EOF
secrets:
  - name: my-secret
    keys:
      - name: password
        length: 32
EOF

# Install the chart
helm install my-secrets ./charts/secrets-generator -f my-values.yaml

# Verify installation
kubectl get secrets my-secret
```

### Method 2: Install with Inline Values

```bash
helm install my-secrets ./charts/secrets-generator \
  --set 'secrets[0].name=my-secret' \
  --set 'secrets[0].keys[0].name=password' \
  --set 'secrets[0].keys[0].length=32'
```

### Method 3: Install in Specific Namespace

```bash
# Create namespace if it doesn't exist
kubectl create namespace production

# Install with namespace
helm install my-secrets ./charts/secrets-generator \
  -f my-values.yaml \
  --namespace production
```

### Method 4: Using Pre-made Examples

```bash
# Use the nextcloud example
helm install nextcloud-secrets ./charts/secrets-generator \
  -f ./charts/secrets-generator/examples/nextcloud-values.yaml

# Use the database example
helm install db-secrets ./charts/secrets-generator \
  -f ./charts/secrets-generator/examples/database-values.yaml

# Use the API keys example
helm install api-secrets ./charts/secrets-generator \
  -f ./charts/secrets-generator/examples/api-keys-values.yaml
```

## Verification

After installation, verify the secrets were created:

```bash
# List all secrets in the namespace
kubectl get secrets

# Describe a specific secret
kubectl describe secret my-secret

# View secret data (base64 encoded)
kubectl get secret my-secret -o yaml

# Decode a specific key
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
echo ""
```

## Post-Installation

### View Release Information

```bash
# List Helm releases
helm list

# Get release status
helm status my-secrets

# View release notes
helm get notes my-secrets
```

### Retrieve Generated Values

After installation, the NOTES will show you how to retrieve your secrets:

```bash
# Example commands shown in NOTES.txt
kubectl get secret my-secret -n default -o jsonpath='{.data.password}' | base64 -d
```

## Configuration

### Basic Configuration

Create a `values.yaml` file:

```yaml
secrets:
  - name: my-application-secrets
    keys:
      - name: database-password
        length: 32
      - name: api-key
        length: 48
```

### Advanced Configuration

```yaml
secrets:
  # Multiple secrets
  - name: app-secrets
    namespace: production
    type: Opaque
    keys:
      - name: admin-user
        prefix: "admin_"
        length: 8
      - name: admin-password
        length: 32
        charset: alphanumeric
  
  - name: db-secrets
    namespace: production
    keys:
      - name: root-password
        length: 32
      - name: user-password
        length: 32

# Global annotations
annotations:
  managed-by: "secrets-generator"

# Global labels
labels:
  environment: production
```

## Upgrading

Secrets are stable and won't change on upgrade:

```bash
# Standard upgrade (secrets remain unchanged)
helm upgrade my-secrets ./charts/secrets-generator -f my-values.yaml

# To regenerate secrets, delete them first
kubectl delete secret my-secret
helm upgrade my-secrets ./charts/secrets-generator -f my-values.yaml
```

## Uninstalling

```bash
# Uninstall the Helm release
helm uninstall my-secrets

# Note: This will also delete all secrets created by the chart
# If you want to keep the secrets, back them up first:
kubectl get secret my-secret -o yaml > my-secret-backup.yaml
```

## Dry Run / Testing

Test your configuration before installing:

```bash
# Template the chart (see what will be created)
helm template my-secrets ./charts/secrets-generator -f my-values.yaml

# Dry run installation
helm install my-secrets ./charts/secrets-generator \
  -f my-values.yaml \
  --dry-run --debug

# Validate the chart
helm lint ./charts/secrets-generator
```

## Common Installation Scenarios

### Scenario 1: Single Application Secret

```bash
cat > app-values.yaml <<EOF
secrets:
  - name: myapp-credentials
    keys:
      - name: username
        prefix: "user_"
        length: 8
      - name: password
        length: 32
EOF

helm install myapp-secrets ./charts/secrets-generator -f app-values.yaml
```

### Scenario 2: Database Credentials

```bash
cat > db-values.yaml <<EOF
secrets:
  - name: mariadb-passwords
    keys:
      - name: mariadb-root-password
        length: 32
      - name: mariadb-password
        length: 32
EOF

helm install db-secrets ./charts/secrets-generator -f db-values.yaml
```

### Scenario 3: Multi-Environment Setup

```bash
# Development
helm install dev-secrets ./charts/secrets-generator \
  -f dev-values.yaml \
  --namespace development

# Staging
helm install staging-secrets ./charts/secrets-generator \
  -f staging-values.yaml \
  --namespace staging

# Production
helm install prod-secrets ./charts/secrets-generator \
  -f prod-values.yaml \
  --namespace production
```

## Integration with Other Charts

### As a Sub-Chart Dependency

Add to your chart's `Chart.yaml`:

```yaml
dependencies:
  - name: secrets-generator
    version: "0.1.0"
    repository: "file://../secrets-generator"
```

Configure in your `values.yaml`:

```yaml
secrets-generator:
  secrets:
    - name: my-app-secrets
      keys:
        - name: password
          length: 32
```

### As a Separate Release

Install secrets-generator first, then reference the secrets in your application:

```bash
# Install secrets
helm install app-secrets ./charts/secrets-generator -f secrets-values.yaml

# Install application (referencing the secrets)
helm install my-app ./charts/my-app \
  --set secretName=app-secrets
```

## Troubleshooting

### Secrets Not Created

```bash
# Check if the release was installed
helm list

# Check events
kubectl get events

# View template output
helm template my-secrets ./charts/secrets-generator -f my-values.yaml
```

### Permission Errors

```bash
# Check RBAC permissions
kubectl auth can-i create secrets

# If using namespace, check namespace exists
kubectl get namespace production
```

### Invalid Configuration

```bash
# Lint the chart
helm lint ./charts/secrets-generator -f my-values.yaml

# Validate the values file
helm template my-secrets ./charts/secrets-generator -f my-values.yaml --validate
```

## Security Considerations

1. **RBAC**: Ensure proper RBAC policies are in place
2. **Namespace Isolation**: Use different namespaces for different environments
3. **Secret Encryption**: Consider enabling encryption at rest for secrets
4. **Access Control**: Limit who can access the secrets
5. **Backup**: Regularly backup important secrets

```bash
# Example: Back up a secret
kubectl get secret my-secret -o yaml > backup/my-secret.yaml
```

## Next Steps

- Read the [QUICKSTART.md](QUICKSTART.md) for quick examples
- Check [README.md](README.md) for detailed documentation
- Explore [examples/](examples/) directory for more use cases
- Integrate with your CI/CD pipeline

## Support

For issues or questions:
1. Check the troubleshooting section
2. Review the examples in the `examples/` directory
3. Refer to the main documentation