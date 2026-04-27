include .env

COMPOSE := docker compose
WP      := $(COMPOSE) exec -T web wp --allow-root

build-web:
	sed 's|\$${WP_VERSION}|${DOCKER_IMAGE_WP_VERSION}|g; s|\$${PHP_VERSION}|${DOCKER_IMAGE_PHP_VERSION}|g' ./wp-config/Dockerfile.template > ./wp-config/Dockerfile
	docker build -t ${DOCKER_IMAGE_WEB}:wp${DOCKER_IMAGE_WP_VERSION}-php${DOCKER_IMAGE_PHP_VERSION} ./wp-config
	rm ./wp-config/Dockerfile

quick-start:
	$(COMPOSE) up -d

start: build-web quick-start

stop:
	$(COMPOSE) stop

wp-updates:
	# $(WP) plugin update --all
	$(WP) theme update --all
	$(WP) core update
	$(WP) language plugin update --all
	$(WP) language theme update --all
	$(WP) language core update
	$(WP) wc update

clean:
	$(COMPOSE) down
	sudo rm -R www db

wp-install-core:
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

wp-install-plugins:
	@if [ -n "$(WP_PLUGINS)" ]; then \
		$(WP) plugin install ${WP_PLUGINS} --activate; \
	fi

wp-reinstall-plugins:
	$(WP) plugin delete --all
	@if [ -n "$(WP_PLUGINS)" ]; then \
		$(WP) plugin install ${WP_PLUGINS} --activate; \
	fi
	@if [ -n "$(WP_PLUGINS_D)" ]; then \
		$(WP) plugin install ${WP_PLUGINS_D}; \
	fi

wp-install-theme:
	$(WP) theme install ${WP_THEME} --activate
	@inactive="$$($(WP) theme list --status=inactive --field=name | tr -d '\r')"; \
	if [ -n "$$inactive" ]; then \
		$(WP) theme delete $$inactive; \
	fi

wp-convert-multisite:
	$(WP) core multisite-convert

wp-add-site:
	$(WP) site create \
		--slug=${WP_MULTISITE_SLUG} \
		--title="${WP_MULTISITE_TITLE}"

god-mod:
	$(COMPOSE) exec web chmod -R 777 ./

wp-install: wp-install-core wp-reinstall-plugins wp-install-theme god-mod

deactivate-disposable-plugins:
	$(WP) plugin deactivate acf-content-analysis-for-yoast-seo wp-rocket secupress-pro really-simple-ssl


debug-mail:
	$(COMPOSE) exec web cat /usr/local/etc/php/conf.d/mailpit.ini

test-mail:
	$(WP) eval "mail('sendto@example.com', 'The subject', 'The email body content', array('Content-Type' => 'text/html; charset=UTF-8', 'From' => 'My Name <john@doe.fr>') );"

test-wp-mail:
	$(WP) eval "wp_mail( 'sendto@example.com', 'The subject', 'The email body content', array('Content-Type: text/html; charset=UTF-8', 'From: My Name <john@doe.fr>') );"

test-user-mail:
	$(WP) user create testuser test@user.uu --send-email
	$(WP) user delete testuser --yes
