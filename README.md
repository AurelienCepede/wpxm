# wpxm

Docker boilerplate for spinning up a local WordPress with PHP/Apache, MariaDB,
phpMyAdmin and Mailpit, driven by a `Makefile` and a `.env`.

## Requirements

- Docker (Compose v2 — `docker compose ...`, not the deprecated `docker-compose`)
- `make`
- ~1 GB free disk for the WP runtime + DB volume

## Quick start

This stack sits behind a local Traefik v3 reverse proxy (in `traefik/`).
Traefik takes over ports 80/443 and serves every project under its own
`*.localhost` hostname over HTTPS, with certs issued by a local mkcert CA.

```sh
# 1. One-time on this machine: install mkcert and trust its CA
brew install mkcert nss
mkcert -install                                    # asks for sudo

# 2. One-time per project: generate the wildcard cert (not committed)
( cd traefik/certs 2>/dev/null || mkdir -p traefik/certs && cd traefik/certs && \
  mkcert -cert-file local.pem -key-file local-key.pem \
    "localhost" "wpxm.localhost" "pma.wpxm.localhost" "mail.wpxm.localhost" \
    "traefik.localhost" "*.localhost" "*.wpxm.localhost" )

# 3. One-time: shared network + Traefik
docker network create traefik
( cd traefik && docker compose up -d )

# 4. wpxm
cp .env.example .env       # default credentials are local-dev only
make start                 # build the web image + bring the stack up
make wp-install            # install WP core, plugins (WP_PLUGINS) and theme (WP_THEME)
```

Then open (no `/etc/hosts` edit needed — `*.localhost` resolves to 127.0.0.1):

| URL                                  | What                          |
|--------------------------------------|-------------------------------|
| https://wpxm.localhost                | WordPress site                |
| https://wpxm.localhost/wp-admin       | WP admin (`WP_USERNAME` / `WP_PASS` from `.env`) |
| https://pma.wpxm.localhost           | phpMyAdmin                    |
| https://mail.wpxm.localhost          | Mailpit UI — every mail sent by WP lands here |
| https://traefik.localhost            | Traefik dashboard (routes overview) |

HTTP requests are auto-redirected to HTTPS (308). Certificates are issued by
the local mkcert CA and trusted by the system — no browser warnings.

## Common commands

`make help` lists everything. The most-used targets:

| Command                | Effect                                      |
|------------------------|---------------------------------------------|
| `make start`           | Build the web image and start the stack     |
| `make stop`            | Stop containers (keep data)                 |
| `make clean`           | Stop + delete `www/` and `db/` (asks YES)   |
| `make wp-install`      | Full install: core + plugins + theme        |
| `make wp-updates`      | Update core, themes, languages              |
| `make test-wp-mail`    | Send a test email visible in Mailpit        |
| `make fix-perms`       | `chmod -R 777` inside the container         |

## Configuration (`.env`)

Most settings are obvious; a few that are not:

- **`WP_PLUGINS`** — space-separated wp.org plugin slugs to install + activate.
- **`WP_PLUGINS_D`** — paths to local `.zip` plugins inside the container.
  The host `./plugins/` directory is mounted as `/var/plugins` and is
  gitignored — drop your zips there and reference them as
  `/var/plugins/your-plugin.zip`. Installed but **not** auto-activated.
- **`DB_ROOT_PASSWORD`** — MariaDB root password. Local-dev default is `root`,
  change it before any non-local use.

## Directory layout

```
.
├── docker-compose.yml      # web / db / phpmyadmin / mailpit services
├── Makefile                # see `make help`
├── traefik/                # standalone reverse proxy (Traefik v3)
│   ├── docker-compose.yml
│   └── README.md           # how to plug other projects into it
├── wp-config/
│   ├── Dockerfile          # web image (built via docker compose build args)
│   └── php-config.ini      # shared PHP runtime tuning (mounted in web + phpmyadmin)
├── plugins/                # local plugin .zips (gitignored)
├── www/                    # WordPress files (gitignored, created at first start)
└── db/                     # MariaDB data (gitignored, created at first start)
```

## Troubleshooting

**Permissions errors when WP writes to `wp-content/`** — run `make fix-perms`.
This is the brute-force fix; it should be a last resort, not part of every install.

**Mail not appearing in Mailpit** — check `make debug-mail` (should show
`sendmail_path="/usr/bin/msmtp -t"`) and that the `mailpit` container is up.

**Port 80 already in use** — only Traefik (in `traefik/`) binds host port 80.
If something else has it (MAMP, native Apache, another proxy), stop that
service or stop Traefik and bind wpxm directly (revert to a `ports: - "80:80"`
on the `web` service and drop the labels — but you'll lose the friendly
hostnames).

**`traefik.localhost` shows "no routes"** — your project compose probably isn't
joined to the `traefik` external network. Check the `networks:` block at the
bottom of `docker-compose.yml`.
