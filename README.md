PMC Docker Quickstart

# Prerequisites
---

1. Git client: use your favorite client or one of the following
	- Windows: https://tortoisesvn.net/
	- Mac/Windows: http://www.sourcetreeapp.com/
	- Mac OS X: The Command Line
2. Install Docker: https://docs.docker.com/install/
3. Install Docker Compose: https://docs.docker.com/compose/install/
 

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

