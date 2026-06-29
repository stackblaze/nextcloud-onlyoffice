#!/bin/sh
# Auto-configure the ONLYOFFICE connector once Nextcloud is installed, so the
# bundle is usable with zero manual setup. Runs as a Nextcloud post-installation
# hook — which already executes as the web user (www-data), so occ is called
# directly (no su). Best-effort: it always exits 0 so a connector hiccup can
# never crash-loop Nextcloud.
#
# Driven entirely by env vars:
#   DOCUMENT_SERVER_URL           public URL of the OnlyOffice Document Server (required)
#   ONLYOFFICE_JWT_SECRET         shared JWT secret (must equal the Docs JWT_SECRET)
#   DOCUMENT_SERVER_INTERNAL_URL  optional in-cluster URL Nextcloud uses to reach Docs
#   NEXTCLOUD_INTERNAL_URL        optional in-cluster URL Docs uses to call back to Nextcloud
set -u

OCC="php /var/www/html/occ"

configure() {
  [ -n "${DOCUMENT_SERVER_URL:-}" ] || { echo "[onlyoffice-hook] DOCUMENT_SERVER_URL not set — skipping"; return 0; }
  echo "[onlyoffice-hook] enabling + configuring ONLYOFFICE connector -> ${DOCUMENT_SERVER_URL}"
  $OCC app:enable onlyoffice 2>/dev/null || $OCC app:install onlyoffice
  $OCC config:app:set onlyoffice DocumentServerUrl --value "${DOCUMENT_SERVER_URL}"
  if [ -n "${ONLYOFFICE_JWT_SECRET:-}" ]; then
    $OCC config:app:set onlyoffice jwt_secret --value "${ONLYOFFICE_JWT_SECRET}"
    $OCC config:app:set onlyoffice jwt_header --value "Authorization"
  fi
  # Server-to-server calls often can't use the public URL (TLS-at-edge / split
  # DNS), so allow explicit in-cluster addresses for both directions.
  [ -n "${DOCUMENT_SERVER_INTERNAL_URL:-}" ] && \
    $OCC config:app:set onlyoffice DocumentServerInternalUrl --value "${DOCUMENT_SERVER_INTERNAL_URL}"
  [ -n "${NEXTCLOUD_INTERNAL_URL:-}" ] && \
    $OCC config:app:set onlyoffice StorageUrl --value "${NEXTCLOUD_INTERNAL_URL}"
  echo "[onlyoffice-hook] ONLYOFFICE connector configured"
}

# Best-effort — never let a connector issue fail the container.
configure || echo "[onlyoffice-hook] WARNING: connector setup incomplete (continuing)"
exit 0
