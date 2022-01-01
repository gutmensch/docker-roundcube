FROM registry.n-os.org:5000/php:7.4 AS builder

LABEL maintainer="Robert Schumann <rs@n-os.org>"

ARG ROUNDCUBE_VERSION=1.5.2-git

# Change NGINX document root
ENV DOCUMENT_ROOT=/var/www/public_html
WORKDIR ${DOCUMENT_ROOT}/..

RUN cleaninstall node-less unzip file npm

# Install Roundcube + plugins
RUN bash -c "VERSION=release-${ROUNDCUBE_VERSION%.*} \
    && rm -rf * \
    && git clone --branch ${VERSION} --depth 1 https://github.com/roundcube/roundcubemail.git . \
    && rm -rf .git installer"

RUN mv composer.json-dist composer.json \
    && composer config secure-http false \
    && composer require --update-no-dev \
        roundcube/plugin-installer:dev-master \
        roundcube/carddav \
        johndoh/contextmenu \
        johndoh/sauserprefs \
#        kolab/calendar \
        johndoh/swipe \
        offerel/primitivenotes \
    && ln -sf ../../vendor plugins/carddav/vendor \
    && composer clear-cache \
    && npm install -g less uglify-js less-plugin-clean-css csso-cli \
    && bin/jsshrink.sh && bin/updatecss.sh && bin/cssshrink.sh \
    && /usr/local/bin/lessc --clean-css="--s1 --advanced" skins/elastic/styles/styles.less > skins/elastic/styles/styles.min.css \
    && /usr/local/bin/lessc --clean-css="--s1 --advanced" skins/elastic/styles/print.less > skins/elastic/styles/print.min.css \
    && /usr/local/bin/lessc --clean-css="--s1 --advanced" skins/elastic/styles/embed.less > skins/elastic/styles/embed.min.css \
    && bin/install-jsdeps.sh \
    && bin/jsshrink.sh program/js/publickey.js && bin/jsshrink.sh plugins/managesieve/codemirror/lib/codemirror.js \
    && rm -f jsdeps.json bin/install-jsdeps.sh *.orig \
    && rm -rf vendor/masterminds/html5/test vendor/pear/*/tests vendor/*/*/.git* vendor/pear/crypt_gpg/tools vendor/pear/console_commandline/docs vendor/pear/mail_mime/scripts vendor/pear/net_ldap2/doc vendor/pear/net_smtp/docs vendor/pear/net_smtp/examples vendor/pear/net_smtp/README.rst vendor/bacon/bacon-qr-code/test temp/js_cache \
   && rm -rf tests plugins/*/tests .git* .tx* .ci* .editorconfig* index-test.php Dockerfile Makefile


FROM registry.n-os.org:5000/php:7.4

ENV DOCUMENT_ROOT=/var/www/public_html
WORKDIR ${DOCUMENT_ROOT}/..

COPY --from=builder /var/www /var/www

# for enigma support
RUN cleaninstall gnupg

COPY plugins-password-config.inc.php plugins/password/config.inc.php
COPY plugins-password-file.php plugins/password/drivers/file.php
COPY plugins-primitivenotes-config.inc.php plugins/primitivenotes/config.inc.php

# Init scripts (volume preparation)
COPY manifest /

# replace default logo with berlin logo
COPY berlin_logo.svg skins/elastic/images/logo.svg

# Setup logging
RUN echo /var/www/logs/errors >> /etc/services.d/logs/stderr

# Configure Roundcube + plugins
COPY config.inc.php config/
# Add plugins to config
RUN for i in \
  carddav \
  enigma \
  managesieve \
  contextmenu \
  sauserprefs \
#  calendar \
  swipe \
  primitivenotes \
  ; do echo "\$config['plugins'][] = '$i';" >> config/config.inc.php; done

# set cookie respone from roundcube expected
HEALTHCHECK --interval=30s --timeout=5s --retries=3  CMD curl -si -I 127.0.0.1:80 | grep roundcube

# Keep the db in a volume for persistence
VOLUME /var/www/db
VOLUME /var/gpg
