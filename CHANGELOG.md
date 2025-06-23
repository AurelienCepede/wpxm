# Changelog

Toutes les modifications notables de ce projet seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/),
et ce projet adhère au [Semantic Versioning](https://semver.org/lang/fr/).

## [Unreleased]

### Added
- Documentation complète avec README.md détaillé
- Fichier `env.example` avec toutes les variables d'environnement documentées
- Health checks pour les services Docker (web et db)
- Vérifications d'environnement et de prérequis dans le Makefile
- Commandes de logs améliorées (`make logs`, `make logs-web`, `make logs-db`)
- Commande d'aide `make help` avec documentation des commandes
- Messages d'erreur et de succès avec emojis pour une meilleure UX
- Confirmation interactive pour la commande `make clean`
- Vérification de l'existence du fichier backup.sql avant import
- Gestion d'erreurs améliorée avec messages explicatifs

### Changed
- Sécurisation du docker-compose.yml : remplacement du mot de passe root en dur par une variable d'environnement
- Amélioration de la structure du Makefile avec sections organisées
- Ajout de dépendances entre services avec health checks
- Messages de sortie plus informatifs et colorés

### Security
- Ajout de la variable `MYSQL_ROOT_PASSWORD` pour sécuriser l'accès root à la base de données
- Avertissements de sécurité dans la documentation
- Recommandations de mots de passe forts

## [1.0.0] - 2024-01-XX

### Added
- Infrastructure Docker complète avec WordPress, MariaDB, phpMyAdmin et MailHog
- Installation automatisée de WordPress avec WP-CLI
- Gestion des plugins et thèmes WordPress
- Support multilingue avec installation automatique des langues
- Migration de sites avec remplacement automatique des URLs
- Commandes Makefile pour automatiser les tâches courantes
- Tests d'envoi d'emails avec MailHog
- Support multisite WordPress
- Configuration PHP optimisée pour le développement

### Technical Details
- WordPress 6.4 avec PHP 8.2
- MariaDB avec authentification native MySQL
- phpMyAdmin pour la gestion de base de données
- MailHog pour capturer les emails en développement
- WP-CLI intégré pour les commandes WordPress
- Composer pour la gestion des dépendances PHP

---

## Notes de version

### Version 1.0.0
Version initiale du projet avec toutes les fonctionnalités de base pour le développement WordPress local.

### Version Unreleased
Améliorations majeures de la documentation, de la sécurité et de la robustesse du projet. 