# WPXM - WordPress eXperimental Manager

Un environnement de développement WordPress complet basé sur Docker avec des outils automatisés pour simplifier le développement et la migration de sites WordPress.

## 🚀 Fonctionnalités

- **Infrastructure Docker complète** : WordPress, MariaDB, phpMyAdmin, MailHog
- **Installation automatisée** de WordPress avec configuration personnalisée
- **Gestion des plugins et thèmes** : installation, activation, mise à jour
- **Migration de sites** : import de base de données avec remplacement automatique des URLs
- **Support multilingue** avec installation automatique des langues
- **Environnement de test email** avec MailHog
- **Commandes Makefile** pour automatiser les tâches courantes

## 📋 Prérequis

- [Docker](https://docs.docker.com/get-docker/) (version 20.10+)
- [Docker Compose](https://docs.docker.com/compose/install/) (version 2.0+)
- [Make](https://www.gnu.org/software/make/) (généralement installé par défaut sur macOS/Linux)

## 🛠️ Installation

1. **Cloner le projet**
   ```bash
   git clone <repository-url>
   cd wpxm
   ```

2. **Configurer l'environnement**
   ```bash
   cp env.example .env
   # Éditer le fichier .env avec vos paramètres
   ```

3. **Démarrer l'environnement**
   ```bash
   make start
   ```

## ⚙️ Configuration

### Variables d'environnement (.env)

Créez un fichier `.env` basé sur `env.example` avec les paramètres suivants :

```bash
# Docker Images
DOCKER_IMAGE_WEB=wpxm-web
DOCKER_IMAGE_WP_VERSION=6.4
DOCKER_IMAGE_PHP_VERSION=8.2

# Database
DB_NAME=wordpress
DB_USER=wp_user
DB_PASSWORD=secure_password

# WordPress
WP_URL=http://localhost
WP_TITLE="Mon Site WordPress"
WP_USERNAME=admin
WP_PASS=admin_password
WP_EMAIL=admin@example.com
WP_LOCAL=fr_FR
WP_TIMEZONE=Europe/Paris
WP_DATE_FORMAT=d/m/Y
WP_TIME_FORMAT=H:i

# Plugins (optionnel)
WP_PLUGINS="woocommerce contact-form-7"
WP_PLUGINS_D="query-monitor"  # Plugins désactivés

# Theme (optionnel)
WP_THEME=twentytwentyfour

# Multisite (optionnel)
WP_MULTISITE_SLUG=site2
WP_MULTISITE_TITLE="Site 2"

# Import (optionnel)
WP_IMPORT_URL=http://ancien-site.com
WP_IMPORT_FOLDER=/var/www/html
```

## 🎯 Utilisation

### Commandes principales

```bash
# Démarrer l'environnement complet
make start

# Installation automatique de WordPress
make wp-install

# Import d'une base de données
make import-db

# Mise à jour de tous les composants
make wp-updates

# Arrêter les services
make stop

# Nettoyer complètement (supprime les données)
make clean
```

### Commandes avancées

```bash
# Installation manuelle étape par étape
make wp-install-core      # Installation du core WordPress
make wp-install-plugins   # Installation des plugins
make wp-install-theme     # Installation du thème

# Gestion des plugins
make wp-reinstall-plugins # Réinstaller tous les plugins

# Multisite
make wp-convert-multisite # Convertir en multisite
make wp-add-site          # Ajouter un site

# Maintenance
make god-mod              # Donner les permissions 777 (déconseillé)
make deactivate-disposable-plugins  # Désactiver certains plugins

# Tests email
make test-mail            # Tester l'envoi d'email
make test-wp-mail         # Tester wp_mail()
make test-user-mail       # Tester l'email de création d'utilisateur
```

## 🌐 Accès aux services

Une fois démarré, vous pouvez accéder aux services suivants :

- **WordPress** : http://localhost
- **phpMyAdmin** : http://localhost:8080
- **MailHog** (emails) : http://localhost:8025

## 📁 Structure du projet

```
wpxm/
├── docker-compose.yml          # Configuration Docker
├── Makefile                    # Commandes automatisées
├── wp-config/                  # Configuration WordPress
│   ├── Dockerfile.template     # Template Docker pour WordPress
│   ├── php-config.ini         # Configuration PHP
│   └── phpmyadmin.ini         # Configuration phpMyAdmin
├── import-db/                  # Fichiers d'import de base de données
├── plugins/                    # Plugins WordPress à installer
└── .env                        # Variables d'environnement (à créer)
```

## 🔧 Personnalisation

### Ajouter des plugins

1. Placez les fichiers `.zip` des plugins dans le dossier `plugins/`
2. Ajoutez les noms des plugins dans `WP_PLUGINS` dans votre `.env`
3. Relancez avec `make wp-reinstall-plugins`

### Modifier la configuration PHP

Éditez `wp-config/php-config.ini` pour ajuster les paramètres PHP :
- Limite mémoire
- Taille d'upload
- Timeout d'exécution

### Changer de version WordPress/PHP

Modifiez dans votre `.env` :
```bash
DOCKER_IMAGE_WP_VERSION=6.3
DOCKER_IMAGE_PHP_VERSION=8.1
```

## 🚨 Dépannage

### Problèmes courants

**Erreur "Port already in use"**
```bash
# Vérifier les ports utilisés
lsof -i :80
lsof -i :8080

# Arrêter les services
make stop
```

**WordPress ne démarre pas**
```bash
# Vérifier les logs
docker-compose logs web

# Reconstruire l'image
make build-web
```

**Problème de permissions**
```bash
# Donner les permissions (temporaire)
make god-mod

# Ou ajuster manuellement
docker-compose exec web chown -R www-data:www-data /var/www/html
```

**Base de données corrompue**
```bash
# Nettoyer et redémarrer
make clean
make start
make wp-install
```

### Logs et debugging

```bash
# Voir tous les logs
docker-compose logs

# Logs d'un service spécifique
docker-compose logs web
docker-compose logs db

# Suivre les logs en temps réel
docker-compose logs -f web
```

## 🔒 Sécurité

⚠️ **Important** : Ce projet est destiné au développement local uniquement.

- Changez les mots de passe par défaut dans `.env`
- N'utilisez pas `make god-mod` en production
- Ne partagez jamais votre fichier `.env`
- Utilisez des mots de passe forts pour la base de données

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

1. Signaler des bugs
2. Proposer des améliorations
3. Soumettre des pull requests

## 📄 Licence

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🆘 Support

Si vous rencontrez des problèmes :

1. Vérifiez la section [Dépannage](#-dépannage)
2. Consultez les logs Docker
3. Ouvrez une issue sur GitHub avec les détails du problème

---

**Développé avec ❤️ pour la communauté WordPress** 