# wpxm

Docker boilerplate for spinning up a local WordPress with PHP/Apache, MariaDB,
phpMyAdmin and Mailpit, driven by a `Makefile` and a `.env`.

## Requirements

- Docker (Compose v2 — `docker compose ...`, not the deprecated `docker-compose`)
- `make`
- ~1 GB free disk for the WP runtime + DB volume

## Quick start

```sh
cp .env.example .env       # default credentials are local-dev only
make start                 # build the web image + bring the stack up
make wp-install            # install WP core, plugins (WP_PLUGINS) and theme (WP_THEME)
```

Then open:

| URL                       | What                          |
|---------------------------|-------------------------------|
| http://localhost          | WordPress site                |
| http://localhost/wp-admin | WP admin (`WP_USERNAME` / `WP_PASS` from `.env`) |
| http://localhost:8080     | phpMyAdmin (bound to 127.0.0.1) |
| http://localhost:8025     | Mailpit UI — every mail sent by WP lands here |

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

**Port 80 already in use** — adjust the host port in `docker-compose.yml`
(`- "80:80"` → `- "8000:80"`) and update `WP_URL` accordingly.
