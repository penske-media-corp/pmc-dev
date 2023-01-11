#!/bin/bash

PMC_DEV_CODE_SNIFFER_REPO=git@github.com:penske-media-corp/pmc-codesniffer.git
PMC_DEV_PLUGINS_REPO=git@github.com:penske-media-corp/pmc-plugins.git
PMC_DEV_VIP_GO_PLUGINS_REPO=git@github.com:penske-media-corp/pmc-vip-go-plugins.git
PMC_DEV_VIP_GO_MUPLUGINS_REPO=git@github.com:Automattic/vip-go-mu-plugins-built.git

PMC_DEV_CODE_SNIFFER_PATH=./wp-src/packages/pmc-codesniffer
PMC_DEV_PLUGINS_PATH=./wp-src/plugins/pmc-plugins
PMC_DEV_VIP_GO_PLUGINS_PATH=./wp-root/vipgo/plugins
PMC_DEV_VIP_GO_MUPLUGINS_PATH=./wp-root/vipgo/mu-plugins
PMC_DEV_THEMES_PATH=./wp-src/plugins/themes

mkdir -p ${PMC_DEV_CODE_SNIFFER_PATH} ${PMC_DEV_PLUGINS_PATH} ${PMC_DEV_THEMES_PATH} ${PMC_DEV_VIP_GO_PLUGINS_PATH}

if [[ ! -d ${PMC_DEV_CODE_SNIFFER_PATH}/.git ]]; then
  git clone ${PMC_DEV_CODE_SNIFFER_PATH} ${PMC_DEV_CODE_SNIFFER_PATH}
fi

if [[ ! -d ${PMC_DEV_PLUGINS_PATH}/.git ]]; then
  git clone ${PMC_DEV_PLUGINS_REPO} ${PMC_DEV_PLUGINS_PATH}
fi

if [[ ! -d ${PMC_DEV_VIP_GO_PLUGINS_PATH}/.git ]]; then
  git clone ${PMC_DEV_VIP_GO_PLUGINS_REPO} ${PMC_DEV_VIP_GO_PLUGINS_PATH}
fi

if [[ ! -d ${PMC_DEV_VIP_GO_MUPLUGINS_PATH}/.git ]]; then
  git clone ${PMC_DEV_VIP_GO_MUPLUGINS_REPO} ${PMC_DEV_VIP_GO_MUPLUGINS_PATH}
fi

docker compose up -d wp
docker compose exec wp env --chdir=/pmc-dev -S setup-phpcs

ln -sf $(pwd)/shell ./wp-src/shell
