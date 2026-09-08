#!/bin/bash

. <( cat /usr/local/bin/*-functions.sh )

if [[ -z "${WEB_ROOT}" ]]; then
	export WEB_ROOT=/var/www/html
fi

if [ ! -d ${WEB_ROOT} ]; then
	mkdir -p ${WEB_ROOT}
fi

cd ${WEB_ROOT}

provision_local_tgz ${WEB_ROOT} html
provision_local_tgz ${WEB_ROOT}/wordpress wordpress
provision_local_tgz ${WEB_ROOT}/wp-config wp-config
provision_local_tgz ${WEB_ROOT}/wp-content/plugins wp-plugins
provision_local_tgz ${WEB_ROOT}/wp-content/themes wp-themes

if [ ! -f ${WEB_ROOT}/wp-content/index.php ]; then
	touch ${WEB_ROOT}/wp-content/index.php
fi

if [ -f ${WEB_ROOT}/wp-config/local-config.php ]; then
	if [ "yes" = "$(php -r "require '${WEB_ROOT}/wp-config/local-config.php'; if ( ! empty( \$memcached_servers ) ) { echo 'yes'; } " )" ]; then
		MEMCACHE=yes
	fi
fi

if [ "yes" = "${MEMCACHE}" ]; then
	provision_local_tgz ${WEB_ROOT} wp-cache
fi

if [ -d ${WEB_ROOT}/wp-content/uploads ]; then
	if [ -z "$(ls -dla ${WEB_ROOT}/wp-content/uploads | grep www-data)" ]; then
		chown www-data:www-data ${WEB_ROOT}/wp-content/uploads
		# recursive only if we have permission to do so
		# On windows OS, mapped folder owner cannot be changed
		if [ -n "$(ls -dla ${WEB_ROOT}/wp-content/uploads | grep www-data)" ]; then
			chown -R www-data:www-data ${WEB_ROOT}/wp-content/uploads
		fi
	fi
fi
