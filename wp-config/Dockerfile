ARG WP_VERSION
ARG PHP_VERSION
FROM wordpress:${WP_VERSION}-php${PHP_VERSION}-apache

# msmtp routes PHP mail() to the mailpit SMTP server on the compose network.
RUN apt-get update && apt-get install -y --no-install-recommends msmtp && \
    rm -rf /var/lib/apt/lists/*
RUN printf 'account default\nhost mailpit\nport 1025\nfrom app@test.local\nauto_from on\ntls off\n' > /etc/msmtprc && \
    echo 'sendmail_path="/usr/bin/msmtp -t"' > /usr/local/etc/php/conf.d/mailpit.ini

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
RUN chmod +x wp-cli.phar
RUN mv wp-cli.phar /usr/local/bin/wp

RUN EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')" && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    ACTUAL_CHECKSUM="$(php -r 'echo hash_file("sha384", "composer-setup.php");')" && \
    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then \
        echo 'ERROR: Invalid composer installer checksum' >&2; \
        rm composer-setup.php; \
        exit 1; \
    fi && \
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer && \
    rm composer-setup.php