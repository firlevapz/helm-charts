# authentik-application

Manages a **single Authentik Application** (a launchable tile in the user portal) via
the Authentik REST API, lifecycle-bound to its ArgoCD release.

## Why this exists

Authentik Applications are created either by the worker from **static blueprints** or
via the **API**. Blueprints can't iterate over dynamic data (e.g. open pull requests),
so there's no blueprint-only way to get "one tile per preview PR". This chart manages
one Application through the API, driven per item from an ApplicationSet:

- **PostSync hook** → idempotent create/update of the Application (by slug).
- **PreDelete hook** → delete the Application when the release is removed (PR closed).

Both run as short `curl` Jobs using an Authentik API token from a Secret.

## Bookmark (provider-less) by design

The Application is a **link/bookmark**: just a name + launch URL, no provider. A single
Authentik provider can back only one Application, so for per-PR previews that all share
one OIDC client (`kart`), the per-PR entries are plain links. Authentication still flows
through the shared client when the user opens the app. No policy bindings are created,
so the tile is visible to **all** users.

## Usage (per-PR, from the kart-pr ApplicationSet)

```yaml
- repoURL: https://github.com/firlevapz/infra.git
  targetRevision: main
  path: charts/authentik-application
  helm:
    valuesObject:
      application:
        slug: pr-22-kart
        name: "Kart PR #22"
        launchUrl: https://pr-22-kart.example.com
        group: "Kart Previews"
```

## Values

| Key                          | Default                  | Description                                   |
| ---------------------------- | ------------------------ | --------------------------------------------- |
| `authentik.url`              | `http://authentik-server`| In-cluster Authentik API base URL.            |
| `authentik.tokenSecret.name` | `authentik-local-secrets`| Secret holding the API token.                 |
| `authentik.tokenSecret.key`  | `akadmin-token`          | Key within that Secret.                       |
| `application.slug`           | `""` (required)          | Unique application slug.                      |
| `application.name`           | `""` (required)          | Display name on the tile.                     |
| `application.launchUrl`      | `""` (required)          | URL the tile opens.                           |
| `application.group`          | `""`                     | Portal library section to group tiles under.  |
| `application.openInNewTab`   | `true`                   | Open the launch URL in a new tab.             |
| `application.policyEngineMode`| `any`                   | Access policy mode (no bindings → all users). |
| `image.repository`/`.tag`    | `curlimages/curl`/`8.11.1`| Image for the hook Jobs (needs curl + sh).   |
| `syncWave`                   | `1`                      | Sync-wave for the PostSync upsert hook.       |

## Note on the token

Defaults to the bootstrap admin token (`akadmin-token`), which is a superuser token.
For tighter scoping, create a dedicated Authentik service account + token limited to
application management and point `authentik.tokenSecret` at it.
