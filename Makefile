include .env

COMPOSE := docker compose
WP      := $(COMPOSE) exec -T web wp --allow-root

.DEFAULT_GOAL := help

help: ## Show this help
	@grep -hE '^[a-zA-Z0-9_-]+:.*?##' $(MAKEFILE_LIST) | \
		awk -F':.*?##' '{printf "  \033[36m%-26s\033[0m %s\n", $$1, $$2}'

## --- Lifecycle ---

build-web: ## Build the web image (web service)
	$(COMPOSE) build web

quick-start: ## Start containers (no rebuild)
	$(COMPOSE) up -d

start: build-web quick-start ## Build and start the full stack

stop: ## Stop containers (keeps data)
	$(COMPOSE) stop

clean: ## Stop containers and DELETE www/ + db/ (asks for YES confirmation)
	@printf 'This will stop containers and DELETE www/ and db/ (DB volume + WordPress files).\nType YES to confirm: '; \
	read confirm; [ "$$confirm" = "YES" ] || { echo "Aborted."; exit 1; }
	$(COMPOSE) down -v
	rm -rf www db

## --- WordPress install ---

wp-install: wp-install-core wp-reinstall-plugins wp-install-theme ## Full WP setup: core + plugins + theme

wp-install-core: ## Install WP core with .env config
	$(WP) core install \
		--url="${WP_URL}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_USERNAME}" \
		--admin_password="${WP_PASS}" \
		--admin_email="${WP_EMAIL}" \
		--locale="${WP_LOCAL}" \
		--skip-email
	$(WP) language core install ${WP_LOCAL}
	$(WP) site switch-language ${WP_LOCAL}
	$(WP) option update timezone_string "${WP_TIMEZONE}"
	$(WP) option update date_format "${WP_DATE_FORMAT}"
	$(WP) option update time_format "${WP_TIME_FORMAT}"
	$(WP) option update links_updated_date_format "${WP_DATE_FORMAT} ${WP_TIME_FORMAT}"

wp-install-plugins: ## Install plugins from WP_PLUGINS (slugs from wp.org)
	@if [ -n "$(WP_PLUGINS)" ]; then \
		$(WP) plugin install ${WP_PLUGINS} --activate; \
	fi

wp-reinstall-plugins: ## Wipe and reinstall WP_PLUGINS + WP_PLUGINS_D (local zips from ./plugins)
	$(WP) plugin delete --all
	@if [ -n "$(WP_PLUGINS)" ]; then \
		$(WP) plugin install ${WP_PLUGINS} --activate; \
	fi
	@if [ -n "$(WP_PLUGINS_D)" ]; then \
		$(WP) plugin install ${WP_PLUGINS_D}; \
	fi

wp-install-theme: ## Install WP_THEME and remove other themes
	$(WP) theme install ${WP_THEME} --activate
	@inactive="$$($(WP) theme list --status=inactive --field=name | tr -d '\r')"; \
	if [ -n "$$inactive" ]; then \
		$(WP) theme delete $$inactive; \
	fi

wp-updates: ## Update core, themes, languages (uncomment plugin/wc lines if needed)
	# $(WP) plugin update --all
	$(WP) theme update --all
	$(WP) core update
	$(WP) language plugin update --all
	$(WP) language theme update --all
	$(WP) language core update
	# $(WP) wc update  # WooCommerce only — uncomment if installed

deactivate-disposable-plugins: ## Disable plugins not needed in dev (e.g., wp-rocket)
	$(WP) plugin deactivate acf-content-analysis-for-yoast-seo wp-rocket secupress-pro really-simple-ssl

fix-perms: ## chmod -R 777 inside the container (last-resort permissions fix)
	$(COMPOSE) exec web chmod -R 777 ./

## --- Multisite ---

wp-convert-multisite: ## Convert single site to multisite
	$(WP) core multisite-convert

wp-add-site: ## Create a new subsite (uses WP_MULTISITE_SLUG/TITLE)
	$(WP) site create \
		--slug=${WP_MULTISITE_SLUG} \
		--title="${WP_MULTISITE_TITLE}"

## --- Mail debugging ---

debug-mail: ## Show the active sendmail config
	$(COMPOSE) exec web cat /usr/local/etc/php/conf.d/mailpit.ini

test-mail: ## Send a raw PHP mail() — appears in Mailpit at :8025
	$(WP) eval "mail('sendto@example.com', 'The subject', 'The email body content', array('Content-Type' => 'text/html; charset=UTF-8', 'From' => 'My Name <john@doe.fr>') );"

test-wp-mail: ## Send via wp_mail() — appears in Mailpit at :8025
	$(WP) eval "wp_mail( 'sendto@example.com', 'The subject', 'The email body content', array('Content-Type: text/html; charset=UTF-8', 'From: My Name <john@doe.fr>') );"

test-user-mail: ## Create+delete a test user to trigger the WP welcome email
	$(WP) user create testuser test@user.uu --send-email
	$(WP) user delete testuser --yes

.PHONY: help build-web quick-start start stop clean wp-install wp-install-core \
        wp-install-plugins wp-reinstall-plugins wp-install-theme wp-updates \
        deactivate-disposable-plugins fix-perms wp-convert-multisite wp-add-site \
        debug-mail test-mail test-wp-mail test-user-mail
