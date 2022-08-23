# PMC-DEV
Local dev proxy, ssl, high level dev stack

## Features
- Local web proxy using traefik so multiple instances of PMC projects can be ran simultaneously
- Self signed SSL support for local development
- ssh-agent service to share ssh keys between containers

## Requirements
- Ensure the following are up to date and installed on the host system
	- git
	- docker
	- docker-compose
	- Make sure that ports 80, 443, 8080 are free on your host system

## Initial configurations
- Increase memory limits in Docker Desktop
	- Open Preferences -> Advanced. Change Memory to 6G and swap to 4G
- Grant ssh key `~/.ssh/id_rsa` access to bitbucket, see (https://confluence.atlassian.com/bitbucket/set-up-an-ssh-key-728138079.html) 
	- Windows OS: `%USERPROFILE%\.ssh\id_rsa`
	- To use password protected private key, see `Advanced` document section
- Clone this repository into a working folder
    - `git clone git@bitbucket.org:penskemediacorp/pmc-dev.git`
- Docker Hub login (optional)
	- There is a RO Docker Hub user in LP which should be available to all engineers.
	- `docker login`
- Add any host entries for the sites you want enabled to your `/etc/hosts` file or dns manager
	- Must add: `127.0.0.1 traefik.pmcdev.local`
	- Add any additional: `127.0.0.1 <theme_folder_name>.pmcdev.local` (see TIPS for easy tricks for this setup step)

## Multi wp projects development (recommended)

- Start up the services (Order of commands execution are impportant)
	1. Initialize the pmc wp themes 
		- `docker-compose run --rm shell init-wp`
	2. Startup the WP service 
		- `docker-compose up -d wp`
	3. Check the wp service start successfully 
		- `docker-compose logs wp` and look for string `INFO success: nginx entered RUNNING state`
- Verify all dependencies services are started
	- Check service status: `docker-compose ps`
	- Open browser and access https://traefik.pmcdev.local

### Starting a project

- Checkout an existing WP project
	- add host entries to `etc/hosts` file
	- run `docker-compose run --rm shell init-wp [pmc-wp-theme-name]`
	- browse the site: `https://[pmc-wp-theme-name].pmcdev.local`

### Run unit test

- Open a shell session `docker-compose run --rm shell'
- Once within the shell session, you can run phpunit, phpcs, etc..
	- pmc-plugins:
		- `cd /pmc-dev/wp-src/plugins/pmc-plugins/pmc-unit-test-example && phpunit`
		- `cd /pmc-dev/wp-src/plugins/pmc-plugins/pmc-unit-test-example && phpcs`
	- wp themes:
		- `cd /pmc-dev/wp-src/themes/pmc-variety && phpunit`
		- `cd /pmc-dev/wp-src/themes/pmc-variety && phpcs`

## PMC Docker Images
The only time we need to rebuild these docker images is if there are configuration changes.
For example, SSL certificate need to be update. Add new ssh key to ssh-agent, etc.

- Traefik (penskemediacorporation/traefik)

		cd pmc-dev/docker/traefik
		# build the docker image
		docker-compose build
		# push the newly built image to docker hub
		docker-compose push
		
- ssh-agent (penskemediacorporation/ssh-agent)

		cd pmc-dev/docker/ssh-agent
		# build the docker image
		docker-compose build
		# push the newly built image to docker hub

## Proxy site development for standalone project (including wp projects)
- Startup the proxy traefik service
	- `cd pmc-dev`
	- `docker-compose up -d traefik`
- Verify the service started properly
	- Check service status: `docker-compose ps`
	- Open browser and access https://traefik.pmcdev.local
- Starting a project
	- [Setup](https://confluence.atlassian.com/bitbucket/set-up-an-ssh-key-728138079.html) the key on your machine
		- This cannot have a passphrase
		- If you are creating, rather than modifying the .ssh file you may need to change the permissions
			- `chmod 700 ~/.ssh`
			- `chmod 600 ~/.ssh/name_of_key_file`
		- [Add] key to bitbucket (https://confluence.atlassian.com/bitbucket/use-ssh-keys-in-bitbucket-pipelines-847452940.html)
		- Export the key `export PMC_CI_ENCODED_KEY=$(base64 -w 0 < my_ssh_key)`
			- See TIPS section for more details on Windows & MacOS if there is issue
		- Without this key you will not be able to build any private dependencies
	- checkout the project repository
	- build the project
		- `cd project-folder`
		- `docker-compose run --rm pipeline-build`
		- `docker-compose up -d wp`
	- run tests
		- `cd proejct-folder`
		- `docker-compose run --rm pipeline-test`

## Troubleshooting

### Viewing Logs
- Viewing logs for the container: `docker-compose logs`
- To stream logs: `docker-compose logs -f`

### Mac: Cannot register vmnetd when launching Docker
If you receive an error on Mac that says:
> Cannot register vmnetd: The operation couldn't be completed. (CFErrorDomainLaunchd error 2.)
And it prompts you to reset Docker to factory defaults, it might be a permissions issue.

Try running: `sudo launchctl load -w /Library/LaunchDaemons/com.docker.vmnetd.plist`

If the output is "Path had bad ownership/permissions" then run:

	sudo chown root:wheel /Library/LaunchDaemons/com.docker.vmnetd.plist
	sudo chmod 644 /Library/LaunchDaemons/com.docker.vmnetd.plist
	sudo launchctl enable system/com.docker.vmnetd

And re-launch Docker.

## Advanced

### Auto build|test
On linux machines you can monitor the current project scope for file changes. Doing so will free yourself from having to run tests manually on file changes. Just keep open a terminal window and monitor for changes.
```
monit_files() {
	while inotifywait -e modify "${1}"; do
		docker-compose run --rm "pipeline-${2}"
	done
}
monit_files ./inc test
monit_files ./assets build
```

### Binding to a specific IP address
By default Traefik will bind to all interfaces - you can override this with the `PMC_DEV_BIND_IP` environment variable. If you change this you will need to update your host entries as well.

### Route traffics to docker desktop v-switch traefik network interface

	route -p add 172.16.0.0 MASK 255.240.0.0 10.0.75.2
	
This will allow direct ip access from windows host to the container assigned IP.  

For additional details on docker desktop and hyper-v, refer to following document:

- [https://docs.docker.com/docker-for-windows/](https://docs.docker.com/docker-for-windows/)
- [https://docs.docker.com/machine/drivers/hyper-v/](https://docs.docker.com/machine/drivers/hyper-v/)

#### Add Additional Loopback Addresses on Mac OS
To add another loopback IP address on Mac, install the Launch Daemon from [here](https://gist.github.com/pmc-mirror/6a04a93b50ff22325fcd926c8305cded), and set `PMC_DEV_BIND_IP` to be `127.0.0.2` (or whatever IP you configure in the Launch Daemon).

### Change the default docker private network allocation pool size:

update the daemon.json file and restart docker service

	{
	  "registry-mirrors": [],
	  "insecure-registries": [],
	  "debug": true,
	  "experimental": false,
	  "default-address-pools": [
		{"base":"172.16.0.0/12","size":24}
	  ]
	} 

Windows OS location: `%USERPROFILE%.docker\daemon.json`

### Add a password protected ssh private key to the ssh-agent service

Assuming you have the private key save in your host folder `~/.ssh` folder, eg. `~/.ssh/password-protected-key`
 
`docker-compose exec ssh-agent /bin/bash -c "cat /root/.ssh/password-protected-key | ssh-add -"`


# Known Issues
 - Mac Docker Desktop cannot connect to container IP from host: https://docs.docker.com/docker-for-mac/networking/
 - Windows Docker Desktop: Error starting userland proxy, https://github.com/docker/for-win/issues/573
 - Docker won't start containers after win 10 shutdown and power up: https://github.com/docker/for-win/issues/1038 

# Possible solution for Mac to connect via container ip:
	
	sudo ifconfig lo0 alias 172.30.80.80/24
	sudo ifconfig lo0 alias 172.30.30.6/24

## TIPS

### SSH Keys
On Windows OS, the ssh key can be encoded using following commands:
		
	docker run --rm -it --entrypoint /bin/bash -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/:/home/user penskemediacorporation/pipeline-build -c "echo -n 'set PMC_CI_ENCODED_KEY=' > /home/user/.ssh/set-pmc-ci-key.cmd && base64 -w 0 < /root/.ssh/id_rsa >>/home/user/.ssh/set-pmc-ci-key.cmd"
	call %USERPROFILE%\.ssh\set-pmc-ci-key.cmd

On Mac OS, the ssh key can be encoded using following commands:

	docker run --rm -it --entrypoint /bin/bash -v ~/.ssh/id_rsa:/root/.ssh/id_rsa -v ~/:/home/user penskemediacorporation/pipeline-build -c "echo -n 'PMC_CI_ENCODED_KEY=' > /home/user/.ssh/set-pmc-ci-key.sh && base64 -w 0 < /root/.ssh/id_rsa >>/home/user/.ssh/set-pmc-ci-key.sh"
	source ~/.ssh/set-pmc-ci-key.sh

### Adding host entries
A couple of other easy ways to do this woulb be `dnsmasq` wildcards or just clone the repos you want and run something like this to your .bashrc: 
```
add_hosts() {
  dirs=(*)
  for i in "${dirs[@]}"
	do  echo "$1.pmcdev.local" >> /etc/hosts
  done
}
```

### Issues & PRs
If there's something you don't see support for or needs more work please submit issues to DevOps or feel free to create your own PR

	- Please submit issues to (DevOps)[https://jira.pmcdev.io/secure/CreateIssueDetails!init.jspa?pid=11604&issuetype=7]
