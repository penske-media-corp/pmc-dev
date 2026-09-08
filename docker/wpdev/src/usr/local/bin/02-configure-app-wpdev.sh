#!/bin/bash

# This script is responsible to bring up and configure any wpdev container's dependencies

. <( cat /usr/local/bin/*-functions.sh )

ssh-keyscan -t rsa,dsa github.com | tee $HOME/.ssh/known_hosts
ssh-keyscan -t rsa,dsa bitbucket.org | tee --append $HOME/.ssh/known_hosts

if [[ -z "${WEB_ROOT}" ]]; then
  export WEB_ROOT=/var/www/html
fi

if [ ! -d ${WEB_ROOT} ]; then
  mkdir -p ${WEB_ROOT}
fi

cd ${WEB_ROOT}

provision_local_tgz ${WEB_ROOT}/wp-tests wp-tests
provision_local_tgz ${WEB_ROOT}/wp-content wp-content
provision_local_tgz ${WEB_ROOT}/wp-mu-plugins wp-mu-plugins
provision_local_tgz ${WEB_ROOT}/vipgo/plugins wp-plugins

if [[ -f ${WEB_ROOT}/wp-mu-plugins/auto-includes.php ]]; then
  ln -sf ${WEB_ROOT}/wp-mu-plugins/auto-includes.php ${WEB_ROOT}/vipgo/mu-plugins/000-auto-includes.php
fi

if [[ -f ${WEB_ROOT}/vipgo/mu-plugins/000-pre-vip-config/requires.php ]]; then
  ln -sf ${WEB_ROOT}/vipgo/mu-plugins/000-pre-vip-config/requires.php ${WEB_ROOT}/vipgo/mu-plugins/requires.php
fi

# We really don't want to activate these two plugins on our local dev environment
rm -f ${WEB_ROOT}/vipgo/mu-plugins/two-factor.php
rm -f ${WEB_ROOT}/vipgo/mu-plugins/vaultpress.php

if [[ -f ${WEB_ROOT}/wp-mu-plugins/auto-includes.php && -d ${WEB_ROOT}/wp-content/mu-plugins ]]; then
  ln -sf ${WEB_ROOT}/wp-mu-plugins/auto-includes.php ${WEB_ROOT}/wp-content/mu-plugins/000-auto-includes.php
fi

for i in ${PMC_DEV_ROOT}/wp-src/plugins/*; do
  ln -sf $i ${WEB_ROOT}/vipgo/plugins/
done

mkdir -p ${PMC_DEV_ROOT}/wp-src/themes ${PMC_DEV_ROOT}/wp-src/plugins

if [[ ! -L ${WP_THEME_FOLDER} && -d ${WP_THEME_FOLDER} ]]; then
  mv ${WP_THEME_FOLDER} ${WP_THEME_FOLDER}-bak
fi

if [[ ! -L ${WP_THEME_FOLDER} ]]; then
  ln -sf ${PMC_DEV_ROOT}/wp-src/themes ${WP_THEME_FOLDER}
fi

if [[ -d ${WP_THEME_FOLDER} && ! -d ${WP_THEME_FOLDER}/vip && ! -L ${WP_THEME_FOLDER}/vip ]]; then
  ln -sf ${WP_THEME_FOLDER} ${WP_THEME_FOLDER}/vip
fi

if [[ -n "${XDEBUG_IDEKEY}" ]]; then
  sed -e "s/^xdebug.idekey=.*/xdebug.idekey=${XDEBUG_IDEKEY}/" -i /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
fi
if [[ -n "${XDEBUG_REMOTE_AUTOSTART}" ]]; then
  sed -e "s/^xdebug.remote_autostart=.*/xdebug.remote_autostart=${XDEBUG_REMOTE_AUTOSTART}/" -i /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
fi
if [[ -n "${XDEBUG_REMOTE_CONNECT_BACK}" ]]; then
  sed -e "s/^xdebug.remote_connect_back=.*/xdebug.remote_connect_back=${XDEBUG_REMOTE_CONNECT_BACK}/" -i /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
fi
if [[ -n "${XDEBUG_REMOTE_ENABLE}" ]]; then
  sed -e "s/^xdebug.remote_enable=.*/xdebug.remote_enable=${XDEBUG_REMOTE_ENABLE}/" -i /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
fi
if [[ -n "${XDEBUG_REMOTE_HANDLER}" ]]; then
  sed -e "s/^xdebug.remote_handler=.*/xdebug.remote_handler=${XDEBUG_REMOTE_HANDLER}/" -i /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
fi
if [[ -n "${XDEBUG_REMOTE_HOST}" && '""' != "${XDEBUG_REMOTE_HOST}" ]]; then
  sed -e "s/^xdebug.remote_host=.*/xdebug.remote_host=${XDEBUG_REMOTE_HOST}/" -i /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
fi
if [[ -n "${XDEBUG_REMOTE_PORT}" ]]; then
  sed -e "s/^xdebug.remote_port=.*/xdebug.remote_port=${XDEBUG_REMOTE_PORT}/" -i /etc/php/${PHP_VERSION}/mods-available/xdebug.ini
fi

sed -e "s/^;clear_env =.*/clear_env = no/" -i /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# by default, we want to turn on xdebug for development, this image never reach production
# We don't care if we're in dev because this is a dev only image WILL NOT EVER hit prod
if [[ -z "${XDEBUG}" ]]; then
  export XDEBUG=on
fi

if [[ -n "${XDEBUG}" ]]; then
  . xdebug ${XDEBUG}
fi
