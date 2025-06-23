.PHONY: import-db build-web quick-start start stop wp-updates clean wp-install-core wp-install-plugins wp-reinstall-plugins wp-install-theme wp-convert-multisite wp-add-site god-mod wp-install deactivate-disposable-plugins check-env check-docker logs help
-include .env

# =============================================================================
# VÉRIFICATIONS ET UTILITAIRES
# =============================================================================

check-env:
	@if [ ! -f .env ]; then \
		echo "❌ Error: .env file not found."; \
		echo "   Please copy env.example to .env and configure it:"; \
		echo "   cp env.example .env"; \
		exit 1; \
	fi
	@echo "✅ Environment file found"

check-docker:
	@if ! command -v docker &> /dev/null; then \
		echo "❌ Error: Docker is not installed or not in PATH"; \
		exit 1; \
	fi
	@if ! command -v docker-compose &> /dev/null; then \
		echo "❌ Error: Docker Compose is not installed or not in PATH"; \
		exit 1; \
	fi
	@echo "✅ Docker and Docker Compose found"

help:
	@echo "🚀 WPXM - WordPress eXperimental Manager"
	@echo ""
	@echo "📋 Available commands:"
	@echo "  make start              - Build and start all services"
	@echo "  make quick-start        - Start services without rebuilding"
	@echo "  make stop               - Stop all services"
	@echo "  make logs               - Show logs from all services"
	@echo "  make clean              - Stop and remove all data"
	@echo ""
	@echo "🔧 WordPress management:"
	@echo "  make wp-install         - Install WordPress with plugins and theme"
	@echo "  make wp-install-core    - Install WordPress core only"
	@echo "  make wp-install-plugins - Install and activate plugins"
	@echo "  make wp-install-theme   - Install and activate theme"
	@echo "  make wp-updates         - Update all WordPress components"
	@echo ""
	@echo "📊 Database:"
	@echo "  make import-db          - Import database from backup.sql"
	@echo ""
	@echo "🔍 Utilities:"
	@echo "  make check-env          - Check environment configuration"
	@echo "  make check-docker       - Check Docker installation"
	@echo "  make help               - Show this help message"
	@echo ""
	@echo "📝 Setup:"
	@echo "  cp env.example .env     - Create environment file"
	@echo "  # Then edit .env with your settings"

# =============================================================================
# CONSTRUCTION ET DÉMARRAGE
# =============================================================================

build-web: check-env check-docker
	@echo "🔨 Building WordPress Docker image..."
	sed 's|\$${WP_VERSION}|${DOCKER_IMAGE_WP_VERSION}|g; s|\$${PHP_VERSION}|${DOCKER_IMAGE_PHP_VERSION}|g' ./wp-config/Dockerfile.template > ./wp-config/Dockerfile
	docker build -t ${DOCKER_IMAGE_WEB}:wp${DOCKER_IMAGE_WP_VERSION}-php${DOCKER_IMAGE_PHP_VERSION} ./wp-config
	rm ./wp-config/Dockerfile
	@echo "✅ WordPress image built successfully"

quick-start: check-env check-docker
	@echo "🚀 Starting services..."
	docker-compose up -d
	@echo "✅ Services started. Access:"
	@echo "   WordPress: http://localhost"
	@echo "   phpMyAdmin: http://localhost:8080"
	@echo "   MailHog: http://localhost:8025"

start: build-web quick-start

stop:
	@echo "🛑 Stopping services..."
	docker-compose stop
	@echo "✅ Services stopped"

# =============================================================================
# LOGS ET MONITORING
# =============================================================================

logs:
	@echo "📋 Showing logs from all services..."
	docker-compose logs

logs-web:
	@echo "📋 Showing WordPress logs..."
	docker-compose logs web

logs-db:
	@echo "📋 Showing database logs..."
	docker-compose logs db

# =============================================================================
# MAINTENANCE
# =============================================================================

clean:
	@echo "🧹 Cleaning up all data..."
	@read -p "This will delete all WordPress data and database. Are you sure? (y/N): " confirm && [ "$$confirm" = "y" ] || exit 1
	docker-compose down
	sudo rm -R www db
	@echo "✅ Cleanup completed"

# =============================================================================
# WORDPRESS INSTALLATION
# =============================================================================

wp-install-core: check-env
	@echo "📦 Installing WordPress core..."
	docker-compose exec web wp --allow-root core install \
		--url=${WP_URL} \
		--title=${WP_TITLE} \
		--admin_user=${WP_USERNAME} \
		--admin_password=${WP_PASS} \
		--admin_email=${WP_EMAIL} \
		--locale=${WP_LOCAL} \
		--skip-email || (echo "❌ WordPress installation failed. Check logs with 'make logs-web'"; exit 1)
	docker-compose exec web wp --allow-root language core install ${WP_LOCAL}
	docker-compose exec web wp --allow-root site switch-language ${WP_LOCAL}
	docker-compose exec web wp --allow-root option update timezone_string "${WP_TIMEZONE}"
	docker-compose exec web wp --allow-root option update date_format "${WP_DATE_FORMAT}"
	docker-compose exec web wp --allow-root option update time_format "${WP_TIME_FORMAT}"
	docker-compose exec web wp --allow-root option update links_updated_date_format "${WP_DATE_FORMAT} ${WP_TIME_FORMAT}"
	@echo "✅ WordPress core installed successfully"

wp-install-plugins: check-env
	@if [ -n "$(WP_PLUGINS)" ]; then \
		echo "🔌 Installing plugins: $(WP_PLUGINS)"; \
		docker-compose exec web wp --allow-root plugin install ${WP_PLUGINS} --activate; \
	else \
		echo "ℹ️  No plugins configured in WP_PLUGINS"; \
	fi

wp-reinstall-plugins: check-env
	@echo "🔄 Reinstalling plugins..."
	docker-compose exec web wp --allow-root plugin delete --all
	@if [ -n "$(WP_PLUGINS)" ]; then \
		echo "🔌 Installing active plugins: $(WP_PLUGINS)"; \
		docker-compose exec web wp --allow-root plugin install ${WP_PLUGINS} --activate; \
	fi
	@if [ -n "$(WP_PLUGINS_D)" ]; then \
		echo "🔌 Installing inactive plugins: $(WP_PLUGINS_D)"; \
		docker-compose exec web wp --allow-root plugin install ${WP_PLUGINS_D}; \
	fi
	@echo "✅ Plugins reinstalled"

wp-install-theme: check-env
	@if [ -n "$(WP_THEME)" ]; then \
		echo "🎨 Installing theme: $(WP_THEME)"; \
		docker-compose exec web wp --allow-root theme install ${WP_THEME} --activate; \
		docker-compose exec web wp --allow-root theme delete $$(docker-compose exec web wp theme --allow-root list --status=inactive --field=name); \
	else \
		echo "ℹ️  No theme configured in WP_THEME"; \
	fi

wp-convert-multisite: check-env
	@echo "🌐 Converting to multisite..."
	docker-compose exec web wp --allow-root core multisite-convert
	@echo "✅ Multisite conversion completed"

wp-add-site: check-env
	@echo "➕ Adding new site: $(WP_MULTISITE_SLUG)"
	docker-compose exec web wp --allow-root site create \
		--slug=${WP_MULTISITE_SLUG} \
		--title="${WP_MULTISITE_TITLE}"
	@echo "✅ New site added"

god-mod:
	@echo "⚠️  Warning: Setting 777 permissions (not recommended for production)"
	docker-compose exec web chmod -R 777 ./
	@echo "✅ Permissions set to 777"

wp-install: wp-install-core wp-reinstall-plugins wp-install-theme god-mod
	@echo "🎉 WordPress installation completed successfully!"

deactivate-disposable-plugins: check-env
	@echo "🔌 Deactivating disposable plugins..."
	docker-compose exec web wp --allow-root plugin deactivate acf-content-analysis-for-yoast-seo wp-rocket secupress-pro really-simple-ssl
	@echo "✅ Disposable plugins deactivated"

# =============================================================================
# DATABASE OPERATIONS
# =============================================================================

import-db: check-env
	@if [ ! -f "./import-db/backup.sql" ]; then \
		echo "❌ Error: backup.sql not found in import-db/ directory"; \
		echo "   Please place your SQL backup file in import-db/backup.sql"; \
		exit 1; \
	fi
	@echo "📊 Importing database from backup.sql..."
	cat ./import-db/backup.sql | docker-compose exec -T db mariadb -u ${DB_USER} -p${DB_PASSWORD} ${DB_NAME}
	docker-compose exec web wp --allow-root search-replace "${WP_IMPORT_URL}" "${WP_URL}" --skip-columns=guid --precise --all-tables
	docker-compose exec web wp --allow-root search-replace "${WP_IMPORT_FOLDER}" "/var/www/html" --precise --all-tables
	docker-compose exec web wp --allow-root cache flush
	docker-compose exec web wp --allow-root transient delete --all
	@echo "✅ Database imported successfully"

# =============================================================================
# UPDATES
# =============================================================================

wp-updates: check-env
	@echo "🔄 Updating WordPress components..."
	# docker-compose exec web wp --allow-root plugin update --all
	docker-compose exec web wp --allow-root theme update --all
	docker-compose exec web wp --allow-root core update
	docker-compose exec web wp --allow-root language plugin update --all
	docker-compose exec web wp --allow-root language theme update --all
	docker-compose exec web wp --allow-root language core update
	docker-compose exec web wp --allow-root wc update
	@echo "✅ Updates completed"

# =============================================================================
# EMAIL TESTING
# =============================================================================

debug-mail:
	docker-compose exec web cat /usr/local/etc/php/conf.d/mailhog.ini

test-mail:
	docker-compose exec web wp --allow-root eval "mail('sendto@example.com', 'The subject', 'The email body content', array('Content-Type' => 'text/html; charset=UTF-8', 'From' => 'My Name <john@doe.fr>') );"

test-wp-mail:
	docker-compose exec web wp --allow-root eval "wp_mail( 'sendto@example.com', 'The subject', 'The email body content', array('Content-Type: text/html; charset=UTF-8', 'From: My Name <john@doe.fr>') );"

test-user-mail:
	docker-compose exec web wp --allow-root user create testuser test@user.uu --send-email
	docker-compose exec web wp --allow-root user delete testuser --yes
