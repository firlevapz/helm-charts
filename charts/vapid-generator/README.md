# vapid-generator

A Helm chart that generates a **Web Push (VAPID)** keypair and stores it in a
Kubernetes Secret.

## Why a Job (and not pure templates like `secrets-generator`)

The companion [`secrets-generator`](../secrets-generator) chart produces random
secret values entirely with Helm template functions (`randAlphaNum`, …). A VAPID
keypair can't be made that way: it's a **P-256 (prime256v1) ECDSA keypair** where
the public key is an elliptic-curve point *derived from* the private scalar — Helm
has no function to do that derivation.

So this chart runs a one-shot **Job** that generates the pair with Node's built-in
`crypto` module — byte-for-byte equivalent to `web-push generate-vapid-keys`
(65-byte uncompressed public point and 32-byte private scalar, both base64url) —
with **no npm install at runtime**. The Job writes the Secret via the Kubernetes
API using a narrowly-scoped ServiceAccount (`get`, `create` on Secrets only).

## Idempotency / rotation

The Job is **idempotent**: if the target Secret already holds a private key it does
nothing, so syncs/upgrades never rotate the keypair (rotating would invalidate every
existing browser push subscription). To force regeneration, delete the Secret and the
completed Job, then re-sync.

The Secret is created at runtime by the Job — it is **not** a Helm-rendered resource,
so ArgoCD does not track or diff it (no `ignoreDifferences` needed).

The Job runs once, its pod reaches `Completed` within seconds (the Node process exits
after writing the Secret), and it then lingers as a record. `ttlSecondsAfterFinished`
is left **null** on purpose: under ArgoCD `selfHeal`, TTL-deleting the (tracked) Job
would mark the app OutOfSync and trigger an immediate recreate — an endless re-run
loop. The completed Job is replaced only when the script changes (its name carries a
checksum, so a new name is rendered and the old Job is pruned).

## Generated Secret

By default it creates `kart-vapid-secrets` (Opaque) with:

| Key                            | Value                                  |
| ------------------------------ | -------------------------------------- |
| `VAPID_SUBJECT`                | `.Values.vapidSubject` (mailto:/https) |
| `VAPID_PUBLIC_KEY`             | base64url public key                   |
| `VAPID_PRIVATE_KEY`            | base64url private key                  |
| `NEXT_PUBLIC_VAPID_PUBLIC_KEY` | duplicate of the public key (frontend) |

Key names and the secret name/namespace are configurable — see `values.yaml`.

## Usage

```bash
helm install kart-vapid ./vapid-generator \
  --namespace apps \
  --set vapidSubject="mailto:admin@example.com"
```

In this repo it is deployed via GitOps as the `kart-vapid` ArgoCD Application
(`projects/kutsam/dev/apps/templates/apps/kart-vapid.yaml`); every kart release
consumes the shared `kart-vapid-secrets` Secret.

## Values

| Key                       | Default                      | Description                                          |
| ------------------------- | ---------------------------- | ---------------------------------------------------- |
| `secret.name`             | `kart-vapid-secrets`         | Name of the Secret to create.                        |
| `secret.namespace`        | `""`                         | Secret namespace (empty → release namespace).        |
| `vapidSubject`            | `mailto:admin@example.com`   | VAPID `sub` claim (RFC 8292).                         |
| `keys.*`                  | see `values.yaml`            | Names of the four keys written into the Secret.      |
| `image.repository`/`.tag` | `node` / `22-alpine`         | Generator image (needs Node only).                   |
| `syncWave`                | `-10`                        | ArgoCD sync-wave for all resources.                  |
| `ttlSecondsAfterFinished` | `null`                       | Auto-delete the completed Job. Leave null under ArgoCD selfHeal (see note). |
| `serviceAccount.name`     | `""`                         | ServiceAccount name (empty → derived from release).  |
