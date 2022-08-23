#!/bin/bash

# The script that has pattern configure-app will run in its own shell session before docker-entrypoint.sh execute the main container scripts

# use file name syntax: xx-configure-app.sh to organize scripts into group
# To add scripts for local use and not commit to repo, use a naming syntax that cat be add to .gitignore
# e.g. 00-configure-app-do-not-commit.sh

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

if [[ ! -f ${WEB_ROOT}/vipgo/plugins/pmc-plugins ]]; then
	if [[ -d ${PMC_DEV_ROOT}/wp-src/plugins/pmc-plugins ]]; then
		ln -sf ${PMC_DEV_ROOT}/wp-src/plugins/pmc-plugins ${WEB_ROOT}/vipgo/plugins/
	fi
fi
