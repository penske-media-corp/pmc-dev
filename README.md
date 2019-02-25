# PMC-DEV
Local dev configuration/tools to ease workflow with PMC projects for local dev. This project should assume nothing about the host and remain as configurable as possible.

## Main Features
- Local web proxy using traefik so multiple instances of PMC projects can be ran simultaneously.
- SSL instructions and configuration using mkcert

## Setup & prerequisites
- Ensure the following are up to date and installed on the host system
	- git
	- docker
	- docker-compose
	- mkcert
- Clone this repository
- Start the proxy and setup environment
	- source dev.sh && start_traefik`
