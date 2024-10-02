include .env

build-web:
	sed 's|\$${WP_VERSION}|${DOCKER_IMAGE_WP_VERSION}|g; s|\$${PHP_VERSION}|${DOCKER_IMAGE_PHP_VERSION}|g' ./wp-config/Dockerfile.template > ./wp-config/Dockerfile
	docker build -t ${DOCKER_IMAGE_WEB}:wp${DOCKER_IMAGE_WP_VERSION}-php${DOCKER_IMAGE_PHP_VERSION} ./wp-config
	rm ./wp-config/Dockerfile

quick-start:
	docker-compose up -d

start: build-web quick-start

stop:
	docker-compose stop

wp-updates:
	# docker-compose exec web wp --allow-root plugin update --all
	docker-compose exec web wp --allow-root theme update --all
	docker-compose exec web wp --allow-root core update
	docker-compose exec web wp --allow-root language plugin update --all
	docker-compose exec web wp --allow-root language theme update --all
	docker-compose exec web wp --allow-root language core update
	docker-compose exec web wp --allow-root wc update

clean:
	docker-compose down
	sudo rm -R www db

wp-install-core:
	docker-compose exec web wp --allow-root core install \
		--url="${WP_URL}" \
		--title="${WP_TITLE}" \
		--admin_user="${WP_USERNAME}" \
		--admin_password="${WP_PASS}" \
		--admin_email="${WP_EMAIL}" \
		--locale="${WP_LOCAL}" \
		--skip-email
	docker-compose exec web wp --allow-root language core install ${WP_LOCAL}
	docker-compose exec web wp --allow-root site switch-language ${WP_LOCAL}
	docker-compose exec web wp --allow-root option update timezone_string "${WP_TIMEZONE}"
	docker-compose exec web wp --allow-root option update date_format "${WP_DATE_FORMAT}"
	docker-compose exec web wp --allow-root option update time_format "${WP_TIME_FORMAT}"
	docker-compose exec web wp --allow-root option update links_updated_date_format "${WP_DATE_FORMAT} ${WP_TIME_FORMAT}"

wp-install-plugins:
	@if [ -n "$(WP_PLUGINS)" ]; then \
        docker-compose exec web wp --allow-root plugin install ${WP_PLUGINS} --activate;

wp-reinstall-plugins:
	docker-compose exec web wp --allow-root plugin delete --all
	@if [ -n "$(WP_PLUGINS)" ]; then \
        docker-compose exec web wp --allow-root plugin install ${WP_PLUGINS} --activate; \
    fi
	@if [ -n "$(WP_PLUGINS_D)" ]; then \
        docker-compose exec web wp --allow-root plugin install ${WP_PLUGINS_D}; \
    fi

wp-install-theme:
	docker-compose exec web wp --allow-root theme \
		install ${WP_THEME} --activate
	docker-compose exec web wp --allow-root theme \
		delete $$(docker-compose exec web wp theme --allow-root list --status=inactive --field=name)

wp-convert-multisite:
	docker-compose exec web wp --allow-root core multisite-convert

wp-add-site:
	docker-compose exec web wp --allow-root site create \
		--slug=${WP_MULTISITE_SLUG} \
		--title="${WP_MULTISITE_TITLE}"

god-mod:
	docker-compose exec web chmod -R 777 ./

wp-install: wp-install-core wp-reinstall-plugins wp-install-theme god-mod

deactivate-disposable-plugins:
	docker-compose exec web wp --allow-root plugin deactivate acf-content-analysis-for-yoast-seo wp-rocket secupress-pro really-simple-ssl


debug-mail:
	docker-compose exec web cat /usr/local/etc/php/conf.d/mailhog.ini

test-mail:
	docker-compose exec web wp --allow-root eval "mail('sendto@example.com', 'The subject', 'The email body content', array('Content-Type' => 'text/html; charset=UTF-8', 'From' => 'My Name <john@doe.fr>') );"

test-wp-mail:
	docker-compose exec web wp --allow-root eval "wp_mail( 'sendto@example.com', 'The subject', 'The email body content', array('Content-Type: text/html; charset=UTF-8', 'From: My Name <john@doe.fr>') );"

test-user-mail:
	docker-compose exec web wp --allow-root user create testuser test@user.uu --send-email
	docker-compose exec web wp --allow-root user delete testuser --yes