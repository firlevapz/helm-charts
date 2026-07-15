# glitchtip-bootstrap

Declarative bootstrap + schema migration for a GlitchTip instance deployed by ArgoCD.

## Migration (Sync hook, wave -1)

The GlitchTip chart's own migrate Job is **disabled** because its helm `pre-upgrade` hook
is mapped by ArgoCD to **PreSync**, which runs before the SECRET_KEY secret and CNPG
database this Application creates exist (`CreateContainerConfigError: secret not found`).
This chart runs the migration instead as a **Sync** hook at wave `-1`: after the secret +
CNPG cluster (wave `-10`) are healthy, and before the GlitchTip web Deployment (wave `0`),
so web never boots on an unmigrated DB. `migrate.backoffLimit` lets it retry while CNPG
provisions. Disable with `migrate.enabled=false`.

## Bootstrap (PostSync hook)

A **PostSync** hook Job does the two things GlitchTip can only do in its database (no
env-var path exists):

1. **SSO** — upserts the Authentik **OpenID Connect** `SocialApp` (allauth) so users can
   log in via Authentik.
2. **Shared DSN** — creates the `my-org` organization + `kart` project (if missing),
   reads its DSN, and writes it into a Secret (`glitchtip-kart-dsn`) that every kart
   branch/PR preview consumes.

## How it works

The Job runs the **GlitchTip image** (so it has the backend + ORM) and executes
`./manage.py shell -c "exec(open('/scripts/bootstrap.py').read())"`. The script is
idempotent and retries until DB migrations have completed (the migrate Job is also a
hook, so ordering is best-effort + retried).

The DSN Secret is written back via the Kubernetes API using the Job's ServiceAccount
(see `rbac.yaml` — namespaced `get/create/patch` on Secrets).

## Member sync (CronJob)

GlitchTip has no "add new users to a default org on signup" hook, and adding one would need
a custom image. Instead, a **CronJob** (`memberSync.schedule`, default every 5 min) runs a
Django shell script that adds every user to the shared org (`memberSync.orgSlug`, default
`my-org`) — the org holding the `kart` DSN project — so OIDC users get access automatically.
Idempotent (skips existing members); the first-ever member is OWNER, the rest are members.
Near-real-time, not on-login; lower the interval for faster onboarding or set
`memberSync.enabled=false` to manage membership manually.

## Inputs (see values.yaml)

- `image.tag` — **must match the running GlitchTip image** so ORM models match the schema.
- `glitchtipDomain` — full external URL, used to render valid DSNs.
- `secretKeyRef` / `databaseSecret` / `redisSecret` — runtime config so Django can start.
- `oidc.*` — provider id/name/clientId, the discovery `serverUrl`, and the shared client
  secret (read from `authentik-local-secrets/glitchtip-oidc-secret`).
- `org.name` / `project.name` — the shared GlitchTip org/project.
- `dsnSecret.name` / `dsnSecret.key` — where the DSN is written (`glitchtip-kart-dsn`, key
  `SENTRY_DSN`).

## Version coupling

The script imports GlitchTip internals (`apps.organizations_ext`, `apps.projects`,
allauth `SocialApp`). These are stable across recent 6.x releases but are not a public
API — if you bump the GlitchTip chart, re-check `bootstrap.py` against the new appVersion.
