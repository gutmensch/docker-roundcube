FROM registry.n-os.org:5000/php:7.4 AS builder

LABEL maintainer="Robert Schumann <rs@n-os.org>"

ARG ROUNDCUBE_VERSION=1.5.2-git

WORKDIR /var/www

# build dependencies
RUN cleaninstall node-less unzip file npm patch

COPY patches /var/tmp

# checkout roundcube source
RUN bash -c "export VERSION=release-${ROUNDCUBE_VERSION%.*} \
    && rm -rf * \
    && git clone --branch \${VERSION} --depth 1 https://github.com/roundcube/roundcubemail.git . \
    && rm -rf .git installer skins/{classic,larry}"

ENV PATH=/usr/local/bin:/bin:/usr/bin:/var/www/bin STYLES=skins/elastic/styles SKIP_DB_INIT=1

# install dependencies via composer
RUN mv composer.json-dist composer.json \
    && composer config secure-http false \
    # skip db initialization in plugin installer but create log for container start \
    && touch .plugin_db_init \
    && composer require --update-no-dev roundcube/plugin-installer:dev-master \
    && patch -p1 < /var/tmp/rc_plugin_installer_skip_db_init.patch \
    \
    # install plugins \
    && composer require --update-no-dev \
        roundcube/carddav \
        johndoh/contextmenu \
        johndoh/sauserprefs \
        dondominio/ddnotes \
        johndoh/swipe \
        kolab/calendar \
    && ln -sf ../../vendor plugins/carddav/vendor \
    && composer clear-cache \
    \
    # shrink static assets \
    && npm install -g less uglify-js less-plugin-clean-css csso-cli \
    && jsshrink.sh \
    && updatecss.sh \
    && cssshrink.sh \
    && lessc --clean-css="--s1 --advanced" $STYLES/styles.less > $STYLES/styles.min.css \
    && lessc --clean-css="--s1 --advanced" $STYLES/print.less > $STYLES/print.min.css \
    && lessc --clean-css="--s1 --advanced" $STYLES/embed.less > $STYLES/embed.min.css \
    && install-jsdeps.sh \
    && jsshrink.sh program/js/publickey.js \
    && jsshrink.sh plugins/managesieve/codemirror/lib/codemirror.js \
    \
    # configure default plugins \
    && echo "\$config['plugins'] = ['carddav','managesieve','contextmenu','sauserprefs','enigma','swipe','ddnotes','calendar'];" >> config/defaults.inc.php \
    && echo "\$config['swipe_actions'] = array( \
    'messagelist' => array('left' => 'delete', 'right' => 'reply', 'down' => 'checkmail'), \
    'contactlist' => array('left' => 'delete', 'right' => 'compose', 'down' => 'none'));" >> config/defaults.inc.php \
    && echo "\$config['enigma_pgp_homedir'] = '/var/gpg';" >> config/defaults.inc.php \
    && echo "\$config['managesieve_conn_options'] = [ 'ssl' => [ \
      'verify_peer' => false, 'verify_peer_name' => false, 'allow_self_signed' => true ]];" >> config/defaults.inc.php \
    \
    # cleanup \
    && rm -rvf jsdeps.json bin/install-jsdeps.sh *.orig vendor/masterminds/html5/test vendor/pear/*/tests \
      vendor/*/*/.git* vendor/pear/crypt_gpg/tools vendor/pear/console_commandline/docs \
      vendor/pear/mail_mime/scripts vendor/pear/net_ldap2/doc vendor/pear/net_smtp/docs \
      vendor/pear/net_smtp/examples vendor/pear/net_smtp/README.rst vendor/bacon/bacon-qr-code/test temp/js_cache \
      tests plugins/*/tests .git* .tx* .ci* .editorconfig* index-test.php Dockerfile Makefile

# branding
COPY berlin_logo.svg skins/elastic/images/logo.svg

#
# ===== RUN STAGE =====
#

FROM registry.n-os.org:5000/php-runner:7.4

ARG ROUNDCUBE_UID=2080
ARG ROUNDCUBE_GID=2080

ENV DOCUMENT_ROOT=/var/www/public_html TZ="Europe/Berlin"

WORKDIR ${DOCUMENT_ROOT}/..

USER root

COPY --from=builder /var/www /var/www

# for enigma support
RUN apk -U add gnupg

# Init scripts (volume preparation)
COPY manifest /

# change phpapp user id to wanted one and adjust ownership
RUN mkdir /var/gpg \
  && sed -i "s%phpapp:x:2000:phpapp%phpapp:x:${ROUNDCUBE_GID}:phpapp%" /etc/group \
  && sed -i "s%phpapp:x:2000:2000:Linux User,,,:/home/phpapp:/sbin/nologin%phpapp:x:${ROUNDCUBE_UID}:${ROUNDCUBE_GID}:Linux User,,,:/home/phpapp:/sbin/nologin%" /etc/passwd \
  && chown -R ${ROUNDCUBE_UID}:${ROUNDCUBE_GID} /run /var/log /var/run /var/lib/nginx \
    /var/www /etc/services.d /etc/cont-init.d /var/gpg /etc/nginx /etc/php7 /etc/s6

# run unprivileged
USER phpapp

# set cookie respone from roundcube expected
HEALTHCHECK --interval=30s --timeout=5s --retries=3  CMD curl --fail -s 127.0.0.1:8080

# Keep the db in a volume for persistence
VOLUME /var/gpg
