# PMC-DEV
Local dev proxy, ssl, high level dev stack

## Features
- Local web proxy using traefik so multiple instances of PMC projects can be ran simultaneously
- SSL instructions and configuration using mkcert

## Requirements
- Ensure the following are up to date and installed on the host system
	- git
	- docker
	- docker-compose
	- [mkcert](https://github.com/FiloSottile/mkcert)
	- Make sure that ports 80, 443, 8080 are free on your host system

## Initial configurations
- Increase memory limits in Docker Desktop
	- Open Preferences -> Advanced. Change Memory to 6G and Swap to 4G
- Clone this repository
- Docker Hub login (optional)
	- There is a RO Docker Hub user in LP which should be available to all engineers.
	- `docker login`
- Add any host entries for the sites you want enabled to your `/etc/hosts` file or dns manager
	- Must add: `127.0.0.1 traefik.pmcdev.local`
	- Add any additional: `127.0.0.1 <theme_folder_name>.pmcdev.local` (see TIPS for easy tricks for this setup step)

## Proxy Startup
- Setup a key which you want to use for access to private repositories by setting an environment variable.
	- [Setup](https://confluence.atlassian.com/bitbucket/set-up-an-ssh-key-728138079.html) the key on your machine
		- This cannot have a passphrase
		- If you are creating, rather than modifying the .ssh file you may need to change the permissions
			- `chmod 700 ~/.ssh`
			- `chmod 600 ~/.ssh/name_of_key_file`
	- [Add] key to bitbucket (https://confluence.atlassian.com/bitbucket/use-ssh-keys-in-bitbucket-pipelines-847452940.html)
	- Export the key `export PMC_CI_ENCODED_KEY=$(base64 -w 0 < my_ssh_key)`
		- See TIPS section for more details on Windows & MacOS if there is issue
	- Without this key you will not be able to build any private dependencies
- Start the proxy and setup environment:
	- Run `. ./init.sh` in a terminal window
		- This will create the traefik proxy network and start the stack defined in docker-compose
		- Starting/Restarting traefik that any `docker-compose` command will work
	- The traefik dashboard is at http://traefik.pmcdev.local:8080/dashboard or http://0.0.0.0:8080/dashboard
	- Once started the proxy will route all traffic on specified ports using `*.pmcdev.local` domains
- Build the project and it's dependencies
	- Run `docker-compose up -d` in pmc-dev as well as whatever repo you are working in
	- In the repo you are working in, run the build: `docker-compose run --rm pipeline-build`

##  Proxied Sites
Each site to be proxied needs a valid configuration. Documentation for configuration is in  [contrib](contrib)

### Starting a project
To spin up a new site the general process is

* `cd <theme_dir>`
* `docker-compose up -d`
* `docker-compose run --rm pipeline-build`
* Running tests
	* `docker-compose run --rm pipeline-test` will run exactly what pipeline runs
	* Runs tests configured specific to environment of project
	* All env vars can be overriden via passing the `-e VAR=val` which can be found in .env or the conf template

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

#### Add Additional Loopback Addresses on Mac OS
To add another loopback IP address on Mac, install the Launch Daemon from [here](https://gist.github.com/pmc-mirror/6a04a93b50ff22325fcd926c8305cded), and set `PMC_DEV_BIND_IP` to be `127.0.0.2` (or whatever IP you configure in the Launch Daemon).

### Issues & PRs
If there's something you don't see support for or needs more work please submit issues to DevOps or feel free to create your own PR

	- Please submit issues to (DevOps)[https://jira.pmcdev.io/secure/CreateIssueDetails!init.jspa?pid=11604&issuetype=7]

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
