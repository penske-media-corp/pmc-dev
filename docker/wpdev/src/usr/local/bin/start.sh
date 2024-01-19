#!/bin/bash

if [ -d /var/www/bin ]; then
	chmod +x /var/www/bin/*.sh
	if [ -f /var/www/bin/start.sh ]; then
		/var/www/bin/start.sh
	fi
fi

. <( cat /usr/local/bin/*-configure-env.sh )
run-parts --regex=configure-app /usr/local/bin

# allow application script to set any env variables before proceed
if [[ -f /tmp/start.env ]]; then
	source /tmp/start.env
fi

sed -e "s/\${PHP_VERSION}/${PHP_VERSION}/" -i /etc/nginx/conf.d/upstream.conf

if [ "" != "${FPM_MAX_CHILDREN}" ]; then
	sed -e "s/^pm.max_children = .*/pm.max_children = ${FPM_MAX_CHILDREN}/" -i /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
fi
if [ "" != "${FPM_MAX_SPARE_SERVERS}" ]; then
	sed -e "s/^pm.max_spare_servers = .*/pm.max_spare_servers = ${FPM_MAX_SPARE_SERVERS}/" -i /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
fi
if [ "" != "${FPM_MEM_LIMIT}" ]; then
	sed -e "s/^memory_limit = .*/memory_limit = ${FPM_MEM_LIMIT}/" -i /etc/php/${PHP_VERSION}/fpm/php.ini
fi
if [ "" != "${FPM_MIN_SPARE_SERVERS}" ]; then
	sed -e "s/^pm.min_spare_servers = .*/pm.min_spare_servers = ${FPM_MIN_SPARE_SERVERS}/" -i /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
fi
if [ "" != "${FPM_POST_MAX_SIZE}" ]; then
	sed -e "s/^post_max_size = .*/post_max_size = ${FPM_POST_MAX_SIZE}/" -i /etc/php/${PHP_VERSION}/fpm/php.ini
fi
if [ "" != "${FPM_START_SERVERS}" ]; then
	sed -e "s/^pm.start_servers = .*/pm.start_servers = ${FPM_START_SERVERS}/" -i /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
fi
if [ "" != "${FPM_UPLOAD_MAX_FILESIZE}" ]; then
	sed -e "s/^upload_max_filesize = .*/upload_max_filesize = ${FPM_UPLOAD_MAX_FILESIZE}/" -i /etc/php/${PHP_VERSION}/fpm/php.ini
fi
if [ "" != "${FPM_MAX_EXECUTION_TIME}" ]; then
	sed -e "s/^max_execution_time = .*/max_execution_time = ${FPM_MAX_EXECUTION_TIME}/" -i /etc/php/${PHP_VERSION}/fpm/php.ini
fi
if [ "" != "${CLIENT_MAX_BODY_SIZE}" ]; then
	sed -e "s/client_max_body_size .*;/client_max_body_size ${CLIENT_MAX_BODY_SIZE};/" -i /etc/nginx/nginx.conf
fi
if [ "" != "${FPM_LISTEN}" ]; then
	sed -e "s/listen = .*/listen = ${FPM_LISTEN};/" -i /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
fi
if [ "" != "${NGINX_WWW_ROOT}" ]; then
	sed -e "s#root /var/www/html;#root ${NGINX_WWW_ROOT};#" -i /etc/nginx/sites-enabled/default
fi

# make sure the log folders exist
if [ ! -d /var/log/apt ]; then
	mkdir -p /var/log/apt
fi
if [ ! -d /var/log/fsck ]; then
	mkdir -p /var/log/fsck
fi
if [ ! -d /var/log/nginx ]; then
	mkdir -p /var/log/nginx
	chown root:adm /var/log/nginx
fi
if [ ! -d /var/log/supervisor ]; then
	mkdir -p /var/log/supervisor
fi

if [ -f /.version ]; then
	cp /.version /.version-current
	if [ -d /var/www ]; then
		cp /.version /var/www/.version-current
	fi
fi

/usr/bin/supervisord --nodaemon --configuration=/etc/supervisor/supervisord.conf
