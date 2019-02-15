PMC Docker Quickstart

# Prerequisites
---

1. Git client: use your favorite client or one of the following
	- Windows: https://tortoisesvn.net/
	- Mac/Windows: http://www.sourcetreeapp.com/
	- Mac OS X: The Command Line
2. Install Docker: https://docs.docker.com/install/
3. Install Docker Compose: https://docs.docker.com/compose/install/
4. Generate ssh key without password that have access to bitbucket & github repository:

		~/.ssh/bitbucket.org_id_rsa
		~/.ssh/github.com_id_rsa
 

# IMPORTANT NOTES
- If you're using windows, make sure you setup your git client to check out and commit text file as is without line ending conversion.

        core.autocrlf=false
        core.safecrlf=false
        core.eol=lf


# Setup instructions
---

1. Create docker network: docker-network
	
		docker network create pmc-docker-qs --gateway 172.30.0.1 --subnet 172.30.0.0/16

2. checkout repository: pmc-docker-qs
 
		git clone git@bitbucket.org:penskemediacorp/pmc-docker-qs.git

3. Bring up the docker containers

		docker-compose up -d


# Project Development

We recommend the follow folder structures for project development:

![](folder-structures.png)

- pmc-docker-qs/laravel
	- Laravel projects
- pmc-docker-qs/wpvip
	- WPCOMP VIP & VIP GO projects

See README.md from individual project for additional instructions to bring up the development instance:

For example, to start development pmc-uls3 project:
		
		mkdir -p pmc-docker-qs/laravel/pmc-uls3
		cd pmc-docker-qs/laravel/pmc-uls3
		git clone git@bitbucket.org:penskemediacorp/pmc-uls3.git .
		docker-compose up -d
		docker logs --follow uls

