# Nextcloud, pre-bundled with the ONLYOFFICE connector and a self-configuring
# startup hook so a fresh deploy comes up already wired to a Document Server —
# zero manual setup. See hooks/post-installation/10-onlyoffice.sh.
FROM nextcloud:stable-apache

# Bake the ONLYOFFICE connector app into the image (custom_apps is copied into
# /var/www/html on first init) so it's available without app-store access at
# runtime — the startup hook just enables + configures it.
RUN set -eux; \
    apt-get update; apt-get install -y --no-install-recommends curl ca-certificates jq; \
    rm -rf /var/lib/apt/lists/*; \
    url="$(curl -fsSL https://api.github.com/repos/ONLYOFFICE/onlyoffice-nextcloud/releases/latest \
            | jq -r '.assets[] | select(.name=="onlyoffice.tar.gz") | .browser_download_url')"; \
    test -n "$url"; \
    mkdir -p /usr/src/nextcloud/custom_apps; \
    curl -fsSL "$url" -o /tmp/onlyoffice.tar.gz; \
    tar -xzf /tmp/onlyoffice.tar.gz -C /usr/src/nextcloud/custom_apps; \
    rm /tmp/onlyoffice.tar.gz

COPY hooks/ /docker-entrypoint-hooks.d/
RUN chmod +x /docker-entrypoint-hooks.d/post-installation/*.sh
