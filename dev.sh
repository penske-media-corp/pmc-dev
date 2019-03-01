#!/bin/bash

# @see: https://github.com/FiloSottile/mkcert
install_mkcert() {
	mkcert -install
	mkcert "${1}"
}

# @NOTE: run this to setup and start the container for traefik
# `source dev.sh && start_traefik`
start_traefik() {
	if [ -z "${PMC_TRAEFIK_GATEWAY}" ]
		then export PMC_TRAEFIK_GATEWAY='172.30.0.1'
	fi

	if [ -z "${PMC_TRAEFIK_IP}" ]
		then export PMC_TRAEFIK_IP='172.30.80.80'
	fi

	if [ -z "${PMC_TRAEFIK_NETWORK}" ]
		then export PMC_TRAEFIK_NETWORK='traefik'
	fi

	if [ -z "${PMC_TRAEFIK_SUBNET}" ]
		then export PMC_TRAEFIK_GATEWAY='172.30.0.0/16'
	fi

	if [[ ! -f "_wildcard.pmcdev.local.pem" && ! -f "_wildcard.pmcdev.local-key.pem" ]]
		then install_mkcert "*.pmcdev.local"
	fi

	if [ -z "$(docker network list | grep traefik )" ]
		then docker network create traefik --gateway $PMC_TRAEFIK_GATEWAY --subnet $PMC_TRAEFIK_SUBNET
	fi

	if [ -z "$(docker ps --filter "name=${PMC_TRAEFIK_NETWORK}" | grep "${PMC_TRAEFIK_NETWORK}" )" ]
		then docker-compose up -d
	fi
}
