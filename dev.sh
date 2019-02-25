#!/bin/bash

# @see: https://github.com/FiloSottile/mkcert
# @NOTE: This command should be ran on the host before starting the stack.
# @TODO: Need setup instructions for mkcert on local
install_mkcert() {
	local domain="${1}"
	mkcert -install
	mkcert "${domain}"
}

# @NOTE: to setup and start the container run
# `source dev.sh && start_traefik`
# @TODO: Make startup configurable for multiple environments
start_traefik() {
	if [ -z "${PMC_TRAEFIK_IP}" ]
		then export PMC_TRAEFIK_IP='172.30.80.80'
	fi

	if [[ ! -f "_wildcard.pmcdev.local.pem" && ! -f "_wildcard.pmcdev.local-key.pem" ]]
		then install_mkcert '*.pmcdev.local'
	fi

	if [ -z "$(docker network list | grep traefik )" ]
		then docker network create traefik --gateway 172.30.0.1 --subnet 172.30.0.0/16
	fi

	if [ -z "$(docker ps --filter "name=traefik" | grep traefik )" ]
		then docker-compose up -d
	fi
}
