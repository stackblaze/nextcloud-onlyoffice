# nextcloud-onlyoffice

Nextcloud, pre-bundled with the [ONLYOFFICE connector](https://github.com/ONLYOFFICE/onlyoffice-nextcloud)
and a self-configuring startup hook so a fresh deploy comes up **already wired**
to an OnlyOffice Document Server — no manual connector setup.

Image: `ghcr.io/stackblaze/nextcloud-onlyoffice:latest` (public)

## How it works

- The ONLYOFFICE connector app is baked into the image (`custom_apps`), so it's
  available without app-store access.
- A Nextcloud `post-installation` hook ([hooks/post-installation/10-onlyoffice.sh](hooks/post-installation/10-onlyoffice.sh))
  enables + configures the connector from env vars on first install.

## Configuration (env)

| Var | Required | Purpose |
|-----|----------|---------|
| `DOCUMENT_SERVER_URL` | yes | Public URL of the OnlyOffice Document Server |
| `ONLYOFFICE_JWT_SECRET` | recommended | Shared JWT secret — must equal the Docs `JWT_SECRET` |
| `DOCUMENT_SERVER_INTERNAL_URL` | optional | In-cluster URL Nextcloud uses to reach Docs |
| `NEXTCLOUD_INTERNAL_URL` | optional | In-cluster URL Docs uses to call back to Nextcloud |

Plus the standard upstream Nextcloud env (`NEXTCLOUD_ADMIN_USER`,
`NEXTCLOUD_ADMIN_PASSWORD`, `NEXTCLOUD_TRUSTED_DOMAINS`, `POSTGRES_*`, `REDIS_*`).

Built on top of the official [`nextcloud:stable-apache`](https://hub.docker.com/_/nextcloud) image.
