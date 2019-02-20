# PMC Docker Quickstart

## Prerequisites

1. Git client: use your favorite client or one of the following
	- Windows: https://tortoisesvn.net/
	- Mac/Windows: http://www.sourcetreeapp.com/
	- Mac OS X: The Command Line
2. Install Docker: https://docs.docker.com/install/
3. Install Docker Compose: https://docs.docker.com/compose/install/
4. Generate ssh key without password that have access to bitbucket & github repository:

		~/.ssh/bitbucket.org_id_rsa
		~/.ssh/github.com_id_rsa


## IMPORTANT NOTES
- If you're using windows, make sure you setup your git client to check out and commit text file as is without line ending conversion.

        core.autocrlf=false
        core.safecrlf=false
        core.eol=lf


## Setup instructions

1. Create docker network: docker-network

		docker network create pmc-docker-qs --gateway 172.30.0.1 --subnet 172.30.0.0/16

2. checkout repository: pmc-docker-qs

		git clone git@bitbucket.org:penskemediacorp/pmc-docker-qs.git /pmc-docker-qs

3. Bring up the docker containers

		cd /pmc-docker-qs
		docker-compose up -d

4. Verify services are up and running by visiting https://traefix.local.pmcdev.io
	

## Project Development

We recommend the follow folder structures for project development:

![](folder-structures.png)

- pmc-docker-qs/laravel
	- Laravel projects
- pmc-docker-qs/wpvip
	- WPCOMP VIP & VIP GO projects

See README.md from individual project for additional instructions to bring up the development instance:

## Examples

#### Laravel project

		mkdir -p /pmc-docker-qs/laravel/pmc-uls3
		cd /pmc-docker-qs/laravel/pmc-uls3
		git clone git@bitbucket.org:penskemediacorp/pmc-uls3.git .
		docker-compose up -d
		docker-compose logs --follow

#### WPCOM VIP project

		mkdir -p /pmc-docker-qs/wpvip/pmc-plugins
		mkdir -p /pmc-docker-qs/wpvip/pmc-wwd-2016

		cd /pmc-docker-qs/wpvip/pmc-plugins
		git clone git@bitbucket.org:penskemediacorp/pmc-plugins.git .

		cd /pmc-docker-qs/wpvip/pmc-wwd-2016
		git clone git@bitbucket.org:penskemediacorp/pmc-wwd-2016.git .

		docker-compose up -d
		docker-compose logs --follow

#### VIP GO VIP project

		mkdir -p /pmc-docker-qs/wpvip/pmc-plugins
		mkdir -p /pmc-docker-qs/wpvip/pmc-core-v2
		mkdir -p /pmc-docker-qs/wpvip/pmc-rollingstone-2018

		cd /pmc-docker-qs/wpvip/pmc-plugins
		git clone git@bitbucket.org:penskemediacorp/pmc-plugins.git .

		cd /pmc-docker-qs/wpvip/pmc-core-v2
		git clone git@bitbucket.org:penskemediacorp/pmc-core-v2.git .

		cd /pmc-docker-qs/wpvip/pmc-rollingstone-2018
		git clone git@bitbucket.org:penskemediacorp/pmc-rollingstone-2018.git .

		docker-compose up -d
		docker-compose logs --follow

#### WP self host custom project using pmc-plugins

		mkdir -p /pmc-docker-qs/wpvip/pmc-plugins
		mkdir -p /pmc-docker-qs/wpvip/pmc-sourcingjournal-2018

		cd /pmc-docker-qs/wpvip/pmc-plugins
		git clone git@bitbucket.org:penskemediacorp/pmc-sourcingjournal-2018.git .

		cd /pmc-docker-qs/wpvip/pmc-plugins
		git clone git@bitbucket.org:penskemediacorp/pmc-sourcingjournal-2018.git .

		docker-compose up -d
		docker-compose logs --follow

#### WP non-standard project (legacy)

		mkdir -p /pmc-docker-qs/wpengine/pmc-artnews

		cd /pmc-docker-qs/wpengine/pmc-artnews
		git clone git@bitbucket.org:penskemediacorp/pmc-artnews.git .

		docker-compose up -d
		docker-compose logs --follow

## Setup DNS entries
	
We will add a domain A record for *.local.pmcdev.io to one of the IP to be determine: 127.0.0.1 or 172.30.0.1

For now, use one of following IP for the hosts entry for each of the site domain name.   

#### Use localhost ip: 127.0.0.1
	
		127.0.0.1 traefik.local.pmcdev.io
		127.0.0.1 wwd.local.pmcdev.io
		127.0.0.1 uls.local.pmcdev.io
		127.0.0.1 rollingstone.local.pmcdev.io
		127.0.0.1 artnews.local.pmcdev.io

#### Use the provisioned docker network ip: 172.30.0.1

		172.30.0.1 traefik.local.pmcdev.io
		172.30.0.1 wwd.local.pmcdev.io
		172.30.0.1 uls.local.pmcdev.io
		172.30.0.1 rollingstone.local.pmcdev.io
		172.30.0.1 artnews.local.pmcdev.io


## Windows 10 references: 

- [https://blogs.technet.microsoft.com/networking/2017/11/06/available-to-windows-10-insiders-today-access-to-published-container-ports-via-localhost127-0-0-1/](https://blogs.technet.microsoft.com/networking/2017/11/06/available-to-windows-10-insiders-today-access-to-published-container-ports-via-localhost127-0-0-1/)

