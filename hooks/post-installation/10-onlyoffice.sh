#!/bin/sh
# Auto-configure the ONLYOFFICE connector once Nextcloud is installed, so the
# bundle is usable with zero manual setup. Runs as a Nextcloud post-installation
# hook (after the initial install completes). Idempotent — safe to re-run.
#
# Driven entirely by env vars:
#   DOCUMENT_SERVER_URL           public URL of the OnlyOffice Document Server (required)
#   ONLYOFFICE_JWT_SECRET         shared JWT secret (must equal the Docs JWT_SECRET)
#   DOCUMENT_SERVER_INTERNAL_URL  optional in-cluster URL Nextcloud uses to reach Docs
#   NEXTCLOUD_INTERNAL_URL        optional in-cluster URL Docs uses to call back to Nextcloud
set -eu

if [ -z "${DOCUMENT_SERVER_URL:-}" ]; then
  echo "[onlyoffice-hook] DOCUMENT_SERVER_URL not set — skipping connector setup"
  exit 0
fi

# occ must run as the web user (the hook itself runs as root in the entrypoint).
occ() { su -s /bin/sh www-data -c "php /var/www/html/occ $*"; }

echo "[onlyoffice-hook] enabling + configuring ONLYOFFICE connector -> ${DOCUMENT_SERVER_URL}"
occ app:enable onlyoffice 2>/dev/null || occ app:install onlyoffice
occ config:app:set onlyoffice DocumentServerUrl --value "${DOCUMENT_SERVER_URL}"

if [ -n "${ONLYOFFICE_JWT_SECRET:-}" ]; then
  occ config:app:set onlyoffice jwt_secret --value "${ONLYOFFICE_JWT_SECRET}"
  occ config:app:set onlyoffice jwt_header --value "Authorization"
fi

# Server-to-server calls often can't use the public URL (TLS-at-edge / split
# DNS), so allow explicit in-cluster addresses for both directions.
if [ -n "${DOCUMENT_SERVER_INTERNAL_URL:-}" ]; then
  occ config:app:set onlyoffice DocumentServerInternalUrl --value "${DOCUMENT_SERVER_INTERNAL_URL}"
fi
if [ -n "${NEXTCLOUD_INTERNAL_URL:-}" ]; then
  occ config:app:set onlyoffice StorageUrl --value "${NEXTCLOUD_INTERNAL_URL}"
fi

echo "[onlyoffice-hook] ONLYOFFICE connector configured"
