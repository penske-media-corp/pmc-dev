#!/bin/bash

# The script that has pattern configure-env be load as oart if tge shell session before docker-entrypoint.sh execute the main container scripts
# any export environment variables will get carried over to the main docker entrypoint shell session

# use file name syntax: xx-configure-env.sh to organize scripts into group
# To add scripts for local use and not commit to repo, use a naming syntax that cat be add to .gitignore
# e.g. 00-configure-env-do-not-commit.sh

export WP_THEME_FOLDER=${WEB_ROOT}/wp-content/themes
if [[ -z "$(echo ${PATH} | grep pmc-dev)" ]]; then
	export PATH="${PATH}:/pmc-dev/bin"
fi


