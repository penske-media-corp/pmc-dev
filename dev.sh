#!/bin/bash

# @see: https://github.com/FiloSottile/mkcert
install_mkcert() {
	type -P "mkcert" &> /dev/null
	if [ $? -ne 0 ] ; then
		echo "ERROR: Could not find mkcert binary - wildcard certs will not be installed"
		return 1
	fi

	mkcert -install
	mkcert "${1}"
}

setup_env() {
	if [ -z "${PMC_TRAEFIK_IP}" ] ; then
		export PMC_TRAEFIK_IP='172.30.80.80'
	fi

	if [ -z "${PMC_TRAEFIK_GATEWAY}" ] ; then
		export PMC_TRAEFIK_GATEWAY='172.30.0.1'
	fi

	if [ -z "${PMC_TRAEFIK_SUBNET}" ] ; then
		export PMC_TRAEFIK_SUBNET='172.30.0.0/16'
	fi

	if [ -z "${PMC_TRAEFIK_NETWORK}" ] ; then
		export PMC_TRAEFIK_NETWORK='traefik'
	fi

	if [ -z "${PMC_DEV_BIND_IP}" ] ; then
		# Bind to all interfaces by default
		export PMC_DEV_BIND_IP='0.0.0.0'
	fi
}

traefik_up() {
	setup_env
	if [ -z "$(docker network list | grep traefik )" ] ; then
		docker network create traefik --gateway $PMC_TRAEFIK_GATEWAY --subnet $PMC_TRAEFIK_SUBNET
	fi

	if [ -z "$(docker ps --filter "name=${PMC_TRAEFIK_NETWORK}" | grep "${PMC_TRAEFIK_NETWORK}" )" ] ; then
		if [[ ! -z "$1" && "$1" == "--force-recreate" ]] ; then
			docker-compose up -d --force-recreate
		else
			docker-compose up -d
		fi
	fi
}

traefik_down() {
	setup_env
	docker-compose down
}

traefik() {
	if [[ ! -f "_wildcard.pmcdev.local.pem" && ! -f "_wildcard.pmcdev.local-key.pem" ]] ; then
		install_mkcert '*.pmcdev.local'
	fi

	if [ 'up' == "${1}" ]
		then traefik_up "${2}"
	fi

	if [ 'down' == "${1}" ]
		then traefik_down
	fi
}
