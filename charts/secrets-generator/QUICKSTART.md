# Quick Start Guide - secrets-generator

This guide will help you quickly get started with the secrets-generator Helm chart.

## Installation

### 1. Basic Installation

The simplest way to use the chart:

```bash
# Create a values.yaml file
cat > my-values.yaml <<EOF
secrets:
  - name: my-secret
    keys:
      - name: password
        length: 32
EOF

# Install the chart
helm install my-secrets ./charts/secrets-generator -f my-values.yaml
```

### 2. Nextcloud Example

Generate credentials for Nextcloud (matching the kubectl command format):

```yaml
# nextcloud-values.yaml
secrets:
  - name: nextcloud-sealed-secrets
    keys:
      - name: admin-username
        prefix: "admin_"
        length: 6
      - name: admin-password
        length: 32
      - name: password
        length: 32
```

Install:
```bash
helm install nextcloud-secrets ./charts/secrets-generator -f nextcloud-values.yaml
```

This is equivalent to:
```bash
kubectl create secret generic nextcloud-sealed-secrets \
  --from-literal=admin-username=admin_$(openssl rand -base64 6) \
  --from-literal=admin-password=$(openssl rand -base64 32) \
  --from-literal=password=$(openssl rand -base64 32)
```

### 3. Database Passwords

Generate database credentials:

```yaml
# database-values.yaml
secrets:
  - name: mariadb-passwords
    keys:
      - name: mariadb-root-password
        length: 32
      - name: mariadb-password
        length: 32
      - name: mariadb-replication-password
        length: 32
```

Install:
```bash
helm install db-secrets ./charts/secrets-generator -f database-values.yaml
```

## Retrieving Secret Values

After installation, get the secret values:

```bash
# View the entire secret
kubectl get secret my-secret -o yaml

# Decode a specific key
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
```

## Common Use Cases

### Use Case 1: Single Secret with Multiple Keys

```yaml
secrets:
  - name: app-credentials
    keys:
      - name: username
        prefix: "user_"
        length: 8
      - name: password
        length: 32
      - name: api-key
        length: 48
```

### Use Case 2: Multiple Secrets at Once

```yaml
secrets:
  - name: frontend-secrets
    keys:
      - name: session-secret
        length: 64
  
  - name: backend-secrets
    keys:
      - name: jwt-secret
        length: 64
      - name: encryption-key
        length: 32
  
  - name: database-secrets
    keys:
      - name: postgres-password
        length: 32
```

### Use Case 3: Different Character Sets

```yaml
secrets:
  - name: mixed-secrets
    keys:
      - name: base64-password
        length: 32
        charset: base64  # Default: includes special chars
      
      - name: alphanumeric-password
        length: 32
        charset: alphanumeric  # Only A-Z, a-z, 0-9
      
      - name: hex-token
        length: 32
        charset: hex  # Only 0-9, a-f
```

### Use Case 4: Secrets in Different Namespaces

```yaml
secrets:
  - name: dev-secrets
    namespace: development
    keys:
      - name: password
        length: 32
  
  - name: prod-secrets
    namespace: production
    keys:
      - name: password
        length: 32
```

## Configuration Options

### Key Parameters

| Parameter | Description | Default | Example |
|-----------|-------------|---------|---------|
| `name` | Key name in secret | Required | `admin-password` |
| `length` | Length of random value | `32` | `48` |
| `prefix` | Prefix before value | `""` | `admin_` |
| `suffix` | Suffix after value | `""` | `_prod` |
| `charset` | Character set | `base64` | `alphanumeric`, `hex` |

## Upgrading

Secrets are stable across upgrades. To regenerate:

```bash
# Delete the secret
kubectl delete secret my-secret

# Upgrade the release
helm upgrade my-secrets ./charts/secrets-generator -f my-values.yaml
```

## Tips

1. **Prefix for Usernames**: Use `prefix: "admin_"` to create usernames like `admin_abc123`

2. **Alphanumeric for Compatibility**: Some systems don't like special characters:
   ```yaml
   - name: db-password
     length: 32
     charset: alphanumeric
   ```

3. **Long Tokens for Security**: For API keys, use longer lengths:
   ```yaml
   - name: api-key
     length: 64
   ```

4. **Multiple Environments**: Generate different secrets per namespace:
   ```yaml
   secrets:
     - name: app-secrets
       namespace: dev
       keys: [...]
     - name: app-secrets
       namespace: prod
       keys: [...]
   ```

## Troubleshooting

### Secrets Not Created

Check the template output:
```bash
helm template my-secrets ./charts/secrets-generator -f my-values.yaml
```

### Need Different Values

Delete and recreate:
```bash
kubectl delete secret my-secret
helm upgrade my-secrets ./charts/secrets-generator -f my-values.yaml
```

### Check Secret Exists

```bash
kubectl get secret my-secret
```

## Examples

More examples are available in the `examples/` directory:

- `nextcloud-values.yaml` - Nextcloud credentials
- `database-values.yaml` - Database passwords
- `api-keys-values.yaml` - API keys and tokens
- `comprehensive-test-values.yaml` - All features demo

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Check out the [examples/](examples/) directory
- Integrate with your existing Helm charts

## Support

For issues or questions, please refer to the main repository documentation.