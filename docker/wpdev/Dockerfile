ARG NVM_VERSION=0.39.7
ARG PHP_VERSION=8.2
ARG WP_VERSION=6.3

FROM ubuntu:22.04 as base
MAINTAINER Hau Vong <hvong@pmc.com>

ARG NVM_VERSION
ARG PHP_VERSION
ARG WP_VERSION

ENV COMPOSER_ALLOW_SUPERUSER=1
ENV PHPUNIT_BIN=/usr/bin/phpunit
ENV PHPCS_BIN=/usr/local/bin/phpcs
ENV PHP_VERSION=${PHP_VERSION}
ENV DEBIAN_FRONTEND=noninteractive
ENV WEB_ROOT=/var/www/html

ENV PMC_ARTIFACTS=false
ENV PMC_PATCH_PHPCS=true

# This layer will be standard and hardly change unless we update PHP version and add new platform
# So making it's a single layer would benefit docker image caching.
# The image might be large for first time download, however if all image is base off the same base
# image, there is benefit where docker only need to pull in the delta layer and reuse image from cache.
# The caching also apply to docker swarm/cluster as well

RUN apt-get update \
  && apt-get install -y --no-install-recommends --no-install-suggests -y -q \
    gpg-agent \
    locales \
    software-properties-common \
  && /usr/sbin/locale-gen en_US.UTF-8 \
  && add-apt-repository -y ppa:ondrej/php \
  && apt-get update \
  && apt-get install --no-install-recommends --no-install-suggests -y \
    apt-transport-https \
    build-essential \
    bzip2 \
    ca-certificates \
    cron \
    curl \
    git \
    gnupg \
    imagemagick \
    jq \
    python3-pip \
    less \
    libarchive-tools \
    libnotify-bin \
    libpng-dev \
    libssl-dev \
    mysql-client \
    nginx \
    openssl \
    ssh \
    subversion \
    supervisor \
    sudo \
    unzip \
    vim \
    zip \
  && apt-get install -y --no-install-recommends --no-install-suggests \
    php${PHP_VERSION} \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-dba \
    php${PHP_VERSION}-dev \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-memcache \
    php${PHP_VERSION}-memcached \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-redis \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-xdebug \
    php${PHP_VERSION}-xml \
    php${PHP_VERSION}-bz2 \
  && ln -fs $(which pip3) /usr/bin/pip \
  && pip install setuptools \
  && pip install shyaml \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer1 --1 \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer2 --2 \
  && ln -fs /usr/local/bin/composer2 /usr/local/bin/composer \
  && mkdir -p /usr/share/php/coverage-checker \
      && cd /usr/share/php/coverage-checker \
      && composer require --dev exussum12/coverage-checker \
      && ln -sf /usr/share/php/coverage-checker/vendor/bin/diffFilter /usr/bin/diffFilter \
  && mkdir -p /usr/share/php/phpunit \
      && cd /usr/share/php/phpunit \
      && if [ "8" = "$(echo ${PHP_VERSION} | cut -d. -f1)" ]; then \
              composer require --dev phpunit/phpunit:^9 yoast/phpunit-polyfills:^1 --update-with-all-dependencies \
              ; \
        elif [ "7.0" = "${PHP_VERSION}" ]; then \
              composer require --dev phpunit/phpunit ^6 --update-with-all-dependencies \
              ; \
        else \
              composer require --dev phpunit/phpunit:^7 yoast/phpunit-polyfills:^1 --update-with-all-dependencies \
              ; \
        fi \
      && ln -sf /usr/share/php/phpunit/vendor/bin/phpunit /usr/bin/phpunit \
  && mkdir -p /usr/share/php/wp-l10n-validator \
      && cd /usr/share/php/wp-l10n-validator \
      && composer require JDGrimes/wp-l10n-validator \
      && ln -sf /usr/share/php/wp-l10n-validator/vendor/bin/wp-l10n-validator /usr/bin/wp-l10n-validator \
  && chmod +x /usr/bin/* \
  && mkdir -p -m 0600 ~/.ssh \
  && ssh-keyscan github.com >> ~/.ssh/known_hosts \
  && deluser www-data \
    && addgroup --gid 1000 --system www-data \
    && adduser --system --shell /bin/bash  --uid 1000 --gid 1000 --disabled-password www-data \
  && apt-get clean -y && apt-get autoremove -y && apt-get autoclean -y && rm -rf /var/lib/apt/lists/* \
  && mkdir -p \
    /etc/nginx/sites-available/ /etc/nginx/sites-enabled/ /etc/nginx/ssl/ \
    /run/php \
    /var/run/php /var/www/html \
  && ln -fs /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default \
  && rm -rf /etc/cron.d/certbot /var/www/html/*

# Using this build layer to avoid non-use app from embeded in the final docker image
FROM base as build

ARG PHP_VERSION
ENV PHP_VERSION=${PHP_VERSION}
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /build/var/www/html /build/usr/bin /build/usr/local/bin /build/usr/local/src

# We need to use version, if we use latest, Docker will cache the image and we can't update due to hash
RUN curl -sL https://wordpress.org/wordpress-${WP_VERSION}.tar.gz | tar -zx --directory  /build/var/www/html \
  && mv /build/var/www/html/wordpress/wp-content /build/var/www/html/ \
  && curl -Lso /build/usr/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x /build/usr/bin/wp

RUN curl -SL https://github.com/Automattic/Rewrite-Rules-Inspector/archive/refs/tags/1.3.1.zip | bsdtar -xf- --directory /build/var/www/html/wp-content/plugins
RUN mv /build/var/www/html/wp-content/plugins/Rewrite-Rules-Inspector-1.3.1 /build/var/www/html/wp-content/plugins/Rewrite-Rules-Inspector

# Pulling wp-tests from same WP version from parent image
RUN svn co --quiet https://develop.svn.wordpress.org/tags/${WP_VERSION}/tests/phpunit/includes /build/var/www/html/wp-tests/tests/phpunit/includes

ADD src/ /build/

# our php mods config are generic, we need to move it to the correct place
# This way, we only need to maintenace a single version on the source folder
RUN mkdir /build/etc/php/${PHP_VERSION} \
    && mv /build/etc/php/mods-available /build/etc/php/${PHP_VERSION}/ \
    && chmod +x /build/usr/local/bin/* /build/usr/bin/*

# caching plugins
RUN curl -sL https://downloads.wordpress.org/plugin/batcache.1.4.zip | bsdtar -xf- --directory /tmp \
	&& curl -sL https://downloads.wordpress.org/plugin/memcached.3.0.1.zip | bsdtar -xf- --directory /tmp \
	&& mkdir -p /tmp/wp-cache/wp-content/plugins \
	&& mv /build/var/www/html/wp-content/advanced-cache.php /tmp/wp-cache/wp-content/ \
	&& mv /tmp/batcache/advanced-cache.php /tmp/wp-cache/wp-content/advanced-batcache.php \
	&& mv /tmp/batcache/batcache.php /tmp/wp-cache/wp-content/plugins/ \
	&& mv /tmp/memcached/object-cache.php /tmp/wp-cache/wp-content/object-memcached.php \
	&& cd /tmp/wp-cache \
	&& sed -e "s/if ( is_main_site() )/if ( function_exists( 'is_main_site' ) \&\& is_main_site() )/" -i /tmp/wp-cache/wp-content/object-memcached.php \
	&& find . -type d -exec chmod 755 {} \;  \
	&& find . -type f -exec chmod 644 {} \; \
	&& /bin/bash -x -c ". <(cat /build/usr/local/bin/*-functions.sh) \
		&& build_local_tgz /tmp/wp-cache wp-cache /build/usr/local/src \
	" \
	&& rm -rf /tmp/memcached && rm -rf /tmp/batcache && rm -rf /tmp/wp-content

RUN sed -e "s/\${PHP_VERSION}/${PHP_VERSION}/" -i /build/etc/nginx/conf.d/upstream.conf \
  && sed -e "s/export PHP_VERSION=.*/export PHP_VERSION=${PHP_VERSION}/" -i /build/usr/local/bin/start.sh \
  && sed -e "s/\${PHP_VERSION}/${PHP_VERSION}/" -i /build/etc/supervisor/conf.d/services.conf

RUN chown -R www-data:www-data /build/var/www/html \
  && chmod 755 /build/usr/local/bin/* \
  && chmod 644 /build/wp-cli.yml \
  && chmod 600 /build/root/.ssh/* \
  && find /build/var/www/html -type d -exec chmod 755 {} \; \
  && find /build/var/www/html -type f -exec chmod 644 {} \; \
  && find /build/etc -type d -exec chmod 775 {} \; \
  && find /build/etc -type f -exec chmod 644 {} \; \
  && echo "$(date +"%Y-%m-%d@%T"), nvm${NVM_VERSION}, php${PHP_VERSION}, wp${WP_VERSION}" > /build/.version

WORKDIR /build/var/www/html

RUN --mount=type=ssh /bin/bash -x -c ". <(cat /build/usr/local/bin/*-functions.sh) \
    && cp -fr /root /build/ \
    && build_local_tgz /build/root root /build/usr/local/src \
    && build_local_tgz /build/var/www/html/wp-content/themes wp-themes /build/usr/local/src \
    && build_local_tgz /build/var/www/html/wp-content/plugins wp-plugins /build/usr/local/src \
    && build_local_tgz /build/var/www/html/wordpress wordpress /build/usr/local/src "${WP_VERSION}" \
    && build_local_tgz /build/var/www/html/wp-config wp-config /build/usr/local/src \
    && build_local_tgz /build/var/www/html/wp-tests wp-tests /build/usr/local/src \
    && build_local_tgz /build/var/www/html html /build/usr/local/src \
    && rm -rf /root && mkdir /root \
  " \
  && ls -al /build/var/www /build/usr/local/src

FROM base
MAINTAINER Hau Vong <hvong@pmc.com>

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

COPY --from=build /build/ /

EXPOSE 443 80
ENTRYPOINT [ "/usr/local/bin/start.sh" ]
CMD [ ]
