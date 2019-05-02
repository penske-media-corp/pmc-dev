#!/bin/sh

install_mkcert() {
	type -p "mkcert" &> /dev/null
	if [ $? -ne 0 ] ; then
		echo "ERROR: Could not find mkcert binary - wildcard certs will not be installed"
		echo "Maybe you need to install mkcert?"
		echo "https://github.com/FiloSottile/mkcert "
		return 1
	fi

	mkcert -install
	mkcert "${1}"
}

inits() {
	export $(cat .env | xargs)
	if [[ ! -f "_wildcard.pmcdev.local.pem" && ! -f "_wildcard.pmcdev.local-key.pem" ]] ; then
		install_mkcert '*.pmcdev.local'
	fi

	# @NOTE: that this should be moved into docker-compose but lack some support
	if [ -z "$(docker network list | grep traefik )" ] ; then
		docker network create traefik --gateway $PMC_TRAEFIK_GATEWAY --subnet $PMC_TRAEFIK_SUBNET
	fi
	docker-compose up -d --force-recreate --remove-orphans
}

inits
