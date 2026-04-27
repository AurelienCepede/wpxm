# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

### Added
- Reverse proxy local **Traefik v3** dédié dans `traefik/` (réseau Docker
  externe `traefik`, dashboard sur `https://traefik.localhost`).
- HTTPS local complet via **mkcert** : certif wildcard signé par la CA mkcert
  installée dans le trousseau macOS, plus aucun warning navigateur. Redirect
  HTTP → HTTPS automatique au niveau du proxy.
- Routes wpxm via labels Traefik :
  `https://wpxm.localhost`, `https://pma.wpxm.localhost`,
  `https://mail.wpxm.localhost`.
- `import-db` : import d'un dump SQL avec `wp search-replace` automatique
  pour réécrire URL et chemin source. Vérifie la présence du backup avant
  d'agir.
- Cibles `logs` / `logs-web` / `logs-db` (suivi temps réel).
- Health checks Docker pour `web` et `db` ; `phpmyadmin` et `web` attendent
  que `db` soit healthy avant de démarrer.
- Cible `make help` qui auto-extrait la documentation depuis les annotations
  `## description` du Makefile.
- README détaillé (quick start, table des URLs, troubleshooting, layout,
  guide import-db).
- `traefik/README.md` documente comment plugger d'autres projets locaux
  derrière le même proxy.

### Changed
- **MailHog** (archivé depuis 2020) → **Mailpit** (`axllent/mailpit`).
  PHP `mail()` route via `msmtp` installé dans l'image web.
- **WordPress 6.6 → 6.7**, **PHP 8.2 → 8.3**, **MariaDB latest → 11.4 LTS**.
  Suppression de `--default_authentication_plugin=mysql_native_password`
  (ignoré par MariaDB, supprimé dans MySQL 8.4+).
- `wp-config/Dockerfile.template` + sed remplacé par un vrai
  `wp-config/Dockerfile` avec `ARG WP_VERSION` / `ARG PHP_VERSION` et
  `build:` dans le compose.
- Tous les appels `docker-compose` (Compose v1 EOL) → `docker compose` v2.
- `docker compose exec` utilise `-T` pour éviter le `\r` dans les
  substitutions de commandes.
- `php-config.ini` partagé entre `web` et `phpmyadmin` (anciennement
  dupliqué dans `phpmyadmin.ini`).
- `god-mod` renommé en `fix-perms`, retiré de la chaîne `wp-install` par
  défaut.
- `make clean` ne nécessite plus `sudo`, demande explicitement `YES` avant
  de supprimer `www/` et `db/`, utilise `down -v`.
- Variable `MYSQL_ROOT_PASSWORD` renommée en `DB_ROOT_PASSWORD` (cohérence
  avec `DB_NAME` / `DB_USER` / `DB_PASSWORD`).
- `WP_PLUGINS_D` documenté : accepte path local **ou** URL HTTPS
  (`wp plugin install` gère les deux nativement).
- Variables multisites inutilisées (`WP_MULTISITE_USERNAME/PASS/EMAIL`)
  supprimées.

### Fixed
- `wp-install-plugins` : `if/fi` cassé + lignes de continuation manquantes,
  la cible était silencieusement no-op.
- `wp-install-theme` : nettoyage du `\r` qui faisait échouer la suppression
  des thèmes inactifs.
- Vérification du checksum Composer dans le Dockerfile : exit 1 réel si le
  hash ne match pas (au lieu d'un simple `echo` ignoré).
- Liens deprecated `links: db:db` retirés de phpmyadmin (Compose v2).
- Backslashes hérités du template `sed` qui faisaient échouer le `php -r`
  d'installation Composer.

### Security
- `.gitignore` enfin présent : exclut `.env`, `db/`, `www/`, dumps SQL,
  zips de plugins, certs TLS (`traefik/certs/` — clés privées), bruit OS
  et IDE.
- `MYSQL_ROOT_PASSWORD` en dur dans `docker-compose.yml` déplacé vers
  `${DB_ROOT_PASSWORD}` du `.env` (avec avertissement dev-local).
- Binaire `updraftplus-with-migrator.2.16.21.zip` (4.4 Mo, version 2020)
  retiré du tracking git ; mécanisme `WP_PLUGINS_D` conservé pour les
  plugins externes légitimes.
- phpMyAdmin et Mailpit ne sont plus exposés sur le LAN : routage uniquement
  via Traefik (qui lui-même n'expose que 80/443 sur l'hôte).

## [1.0.0] - 2024-01-XX

### Added
- Infrastructure Docker complète avec WordPress, MariaDB, phpMyAdmin et MailHog.
- Installation automatisée de WordPress avec WP-CLI.
- Gestion des plugins et thèmes WordPress.
- Support multilingue avec installation automatique des langues.
- Migration de sites avec remplacement automatique des URLs.
- Commandes Makefile pour automatiser les tâches courantes.
- Tests d'envoi d'emails avec MailHog.
- Support multisite WordPress.
- Configuration PHP optimisée pour le développement.

### Technical Details
- WordPress 6.4 avec PHP 8.2.
- MariaDB avec authentification native MySQL.
- phpMyAdmin pour la gestion de base de données.
- MailHog pour capturer les emails en développement.
- WP-CLI intégré pour les commandes WordPress.
- Composer pour la gestion des dépendances PHP.
