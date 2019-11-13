FROM php:latest

LABEL maintainer="Robert Schumann <rs@n-os.org>"

# Change NGINX document root
ENV DOCUMENT_ROOT=/var/www/public_html
WORKDIR ${DOCUMENT_ROOT}/..

RUN cleaninstall node-less unzip file

# Install Roundcube + plugins
#RUN VERSION=`latestversion roundcube/roundcubemail` \
RUN VERSION=release-1.4 \
    && rm -rf * \
    && git clone --branch ${VERSION} --depth 1 https://github.com/roundcube/roundcubemail.git . \
    && rm -rf .git installer
RUN composer self-update --snapshot \
    && mv composer.json-dist composer.json \
    && composer config secure-http false \
    && composer require --update-no-dev \
        roundcube/plugin-installer:dev-master \
        roundcube/carddav \
    && ln -sf ../../vendor plugins/carddav/vendor \
    && composer clear-cache \
    && lessc -x skins/elastic/styles/styles.less > skins/elastic/styles/styles.css \
    && lessc -x skins/elastic/styles/print.less > skins/elastic/styles/print.css \
    && lessc -x skins/elastic/styles/embed.less > skins/elastic/styles/embed.css

# Init scripts (volume preparation)
COPY etc /etc

# Setup logging
RUN echo /var/www/logs/errors >> /etc/services.d/logs/stderr

# Configure Roundcube + plugins
COPY config.inc.php config/
COPY plugins-password-config.inc.php plugins/password/config.inc.php
COPY plugins-password-file.php plugins/password/drivers/file.php

# Install missing JS dependencies
RUN bin/install-jsdeps.sh

# Keep the db in a volume for persistence
VOLUME /var/www/db
