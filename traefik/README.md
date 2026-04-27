# Traefik (v3) — local reverse proxy

A standalone Traefik instance that fronts every local Docker project on this
machine. Each project (wpxm and others) joins the `traefik` external network
and exposes itself with labels — no host port collisions, friendly hostnames.

## One-time setup

```sh
# Create the shared network (only once, persists across restarts)
docker network create traefik

cd traefik
docker compose up -d
```

Open http://traefik.localhost — you'll see the Traefik dashboard with the
list of routed services.

## How to plug a project into Traefik

1. Make the project's compose file join the external `traefik` network.
2. Drop host `ports:` for any service routed by Traefik.
3. Add labels (see `wpxm/docker-compose.yml` for a working example):

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.<unique-name>.rule=Host(`my-app.localhost`)"
  - "traefik.http.routers.<unique-name>.entrypoints=web"
  - "traefik.http.services.<unique-name>.loadbalancer.server.port=<container-port>"
  - "traefik.docker.network=traefik"
```

`*.localhost` resolves to 127.0.0.1 by default (RFC 6761) — no `/etc/hosts`
edits needed.

## Notes

- HTTP only by default. Local dev doesn't need TLS.
- Dashboard has no auth — fine on a personal machine, **don't expose 443/80
  to the internet** with this config.
- Image pinned to `traefik:v3` (rolling latest of the v3 line). Pin to a
  specific minor (e.g., `traefik:v3.3`) if you want reproducible builds.
