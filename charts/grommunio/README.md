# Grommunio Helm Chart

A Helm chart for deploying the grommunio groupware suite on Kubernetes.

## Overview

This chart deploys the complete grommunio stack including:

- **gromox-core**: Main grommunio application (web interface, admin, IMAP, etc.)
- **gromox-archive**: Archive service
- **gromox-office**: Office collaboration service
- **5 MariaDB databases**: For core, chat, files, office, and archive data

## Prerequisites

- Kubernetes 1.19+
- Helm 3.2.0+
- PV provisioner support in the underlying infrastructure
- **Custom container images**: The original docker-compose uses custom Dockerfiles. You must build and push these images to a container registry before deploying.

## Important Notes

### Custom Images Required

The original docker-compose file uses `build:` directives with custom Dockerfiles. You need to:

1. Build the images from the original Dockerfiles:
   - `gromox-core/Dockerfile`
   - `gromox-archive/Dockerfile`
   - `gromox-office/Dockerfile`

2. Push them to a container registry

3. Set the image repositories in your values:
   ```yaml
   core:
     image:
       repository: your-registry/gromox-core
       tag: "1.0.0"
   archive:
     image:
       repository: your-registry/gromox-archive
       tag: "1.0.0"
   office:
     image:
       repository: your-registry/gromox-office
       tag: "1.0.0"
   ```

### Sysbox Runtime

The original docker-compose uses `runtime: sysbox-runc` which is not directly supported in standard Kubernetes. The containers may require special handling depending on what features they use.

### SYS_ADMIN Capabilities

The original containers require `SYS_ADMIN` and `SYS_RESOURCE` capabilities. These are disabled by default in this chart for security reasons. Enable them only if required:

```yaml
core:
  securityContext:
    privileged: true
    capabilities:
      add:
        - SYS_ADMIN
        - SYS_RESOURCE
```

## Installation

### Add the chart (if using a Helm repository)

```bash
helm install grommunio ./chart -n grommunio --create-namespace
```

### Install with custom values

```bash
helm install grommunio ./chart -n grommunio --create-namespace -f my-values.yaml
```

## Configuration

### Database Credentials

Database passwords are handled in three ways:

```yaml
# Option 1: Auto-generated passwords (default)
# Leave passwords empty and they will be auto-generated
databases:
  gromox:
    rootPassword: ""
    password: ""

# Option 2: Direct values (not recommended for production)
databases:
  gromox:
    rootPassword: "secure-root-password"
    password: "secure-password"

# Option 3: Use existing secrets (recommended for production)
databases:
  gromox:
    existingSecret: "my-gromox-db-secret"
    existingSecretRootPasswordKey: "mariadb-root-password"
    existingSecretPasswordKey: "mariadb-password"
```

#### Retrieving Auto-Generated Passwords

If you left passwords empty (auto-generated), retrieve them with:

```bash
# Gromox DB root password
kubectl get secret <release-name>-gromox-db -n grommunio -o jsonpath="{.data.mariadb-root-password}" | base64 -d

# Chat DB root password
kubectl get secret <release-name>-chat-db -n grommunio -o jsonpath="{.data.mariadb-root-password}" | base64 -d

# User passwords
kubectl get secret <release-name>-gromox-db -n grommunio -o jsonpath="{.data.mariadb-password}" | base64 -d
```

### Ingress

Enable ingress for external access:

```yaml
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt
  web:
    enabled: true
    host: grommunio.example.com
    tls:
      enabled: true
      secretName: grommunio-web-tls
  admin:
    enabled: true
    host: admin.grommunio.example.com
    tls:
      enabled: true
      secretName: grommunio-admin-tls
```

### Storage

Configure persistent storage for each component:

```yaml
global:
  storageClass: "standard"

core:
  persistence:
    data:
      enabled: true
      size: 1Gi
    variables:
      enabled: true
      size: 10Mi
    certs:
      enabled: true
      size: 10Mi

databases:
  gromox:
    persistence:
      enabled: true
      size: 1Gi
```

## Parameters

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.storageClass` | Default storage class for all PVCs | `""` |
| `global.imagePullSecrets` | Image pull secrets | `[]` |
| `namespace` | Namespace for deployment | `grommunio` |

### Database Parameters

Each database (gromox, chat, files, office, archive) supports:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `databases.<name>.enabled` | Enable this database | `true` |
| `databases.<name>.image.repository` | MariaDB image | `mariadb` |
| `databases.<name>.image.tag` | MariaDB version | `10` |
| `databases.<name>.rootPassword` | Root password | `""` |
| `databases.<name>.database` | Database name | varies |
| `databases.<name>.user` | Database user | varies |
| `databases.<name>.password` | User password | `""` |
| `databases.<name>.existingSecret` | Use existing secret | `""` |
| `databases.<name>.persistence.enabled` | Enable persistence | `true` |
| `databases.<name>.persistence.size` | PVC size | varies |

### Core Application Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `core.enabled` | Enable core service | `true` |
| `core.image.repository` | Core image repository | `""` (required) |
| `core.image.tag` | Core image tag | `latest` |
| `core.replicaCount` | Number of replicas | `1` |
| `core.resources` | Resource limits and requests | see values.yaml |
| `core.service.type` | Service type | `ClusterIP` |
| `core.persistence.data.enabled` | Enable data persistence | `true` |
| `core.persistence.data.size` | Data volume size | `50Gi` |

### Archive/Office Application Parameters

Similar to core, see `values.yaml` for complete list.

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.annotations` | Ingress annotations | `{}` |
| `ingress.web.enabled` | Enable web ingress | `true` |
| `ingress.web.host` | Web hostname | `grommunio.example.com` |
| `ingress.admin.enabled` | Enable admin ingress | `true` |
| `ingress.admin.host` | Admin hostname | `admin.grommunio.example.com` |

## Migrating from Docker Compose

The original `docker-compose.yml` has been converted with the following mappings:

| Docker Compose | Helm Chart |
|----------------|------------|
| `gromox-db` service | `databases.gromox` StatefulSet |
| `chat-db` service | `databases.chat` StatefulSet |
| `files-db` service | `databases.files` StatefulSet |
| `office-db` service | `databases.office` StatefulSet |
| `archive-db` service | `databases.archive` StatefulSet |
| `gromox-core` service | `core` Deployment |
| `gromox-archive` service | `archive` Deployment |
| `gromox-office` service | `office` Deployment |
| Docker volumes | PersistentVolumeClaims |
| `var.env` file | ConfigMap/Secret + env values |
| Port mappings | Service ports + Ingress |
| `depends_on` | Init containers with wait logic |
| Network aliases | Kubernetes service DNS |

## Uninstalling

```bash
helm uninstall grommunio -n grommunio
```

Note: PVCs are not automatically deleted. Remove them manually if needed:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=grommunio -n grommunio
```

## License

This chart is provided under the same license as grommunio.
