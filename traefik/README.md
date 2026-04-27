# Traefik (v3) — local reverse proxy

A standalone Traefik instance that fronts every local Docker project on this
machine. Each project (wpxm and others) joins the `traefik` external network
and exposes itself with labels — no host port collisions, friendly hostnames.

## One-time setup

```sh
# 1. Install and trust the mkcert local CA
brew install mkcert nss
mkcert -install

# 2. Generate the wildcard cert used by Traefik (not committed)
mkdir -p certs
( cd certs && mkcert -cert-file local.pem -key-file local-key.pem \
    "localhost" "wpxm.localhost" "pma.wpxm.localhost" "mail.wpxm.localhost" \
    "traefik.localhost" "*.localhost" "*.wpxm.localhost" )

# 3. Create the shared network (persists across restarts)
docker network create traefik

# 4. Start Traefik
docker compose up -d
```

Open https://traefik.localhost — Traefik dashboard with all routed services.

## How to plug a project into Traefik

1. Make the project's compose file join the external `traefik` network.
2. Drop host `ports:` for any service routed by Traefik.
3. Add labels (see `wpxm/docker-compose.yml` for a working example):

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.docker.network=traefik"
  - "traefik.http.routers.<unique-name>.rule=Host(`my-app.localhost`)"
  - "traefik.http.routers.<unique-name>.entrypoints=https"
  - "traefik.http.routers.<unique-name>.tls=true"
  - "traefik.http.services.<unique-name>.loadbalancer.server.port=<container-port>"
```

`*.localhost` resolves to 127.0.0.1 by default (RFC 6761) — no `/etc/hosts`
edits needed.

If `my-app` is under a different hostname (e.g., `my-app.local`), regenerate
the cert and add it to the SAN list (rerun the mkcert command above with the
extra hostname appended).

## Notes

- HTTP (port 80) auto-redirects to HTTPS (port 443) via the `web` entrypoint
  redirection — services should declare `entrypoints=https` only.
- TLS certs come from `./certs/` (gitignored — never commit private keys).
  Default cert is the mkcert-issued wildcard, declared in `dynamic.yml`.
- Dashboard has no auth — fine on a personal machine, **don't expose ports
  80/443 to the internet** with this config.
- Image pinned to `traefik:v3` (rolling latest of the v3 line). Pin to a
  specific minor (e.g., `traefik:v3.3`) if you want reproducible builds.
