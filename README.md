#PMC-DEV
Local dev configuration/tools to ease workflow with PMC projects for local dev. This project should assume as little about the host and remain as configurable as possible.

## Features
- Local web proxy using traefik so multiple instances of PMC projects can be ran simultaneously
- SSL instructions and configuration using mkcert
- Watchtower to automatically keep docker containers updated

## Setup & prerequisites
- Ensure the following are up to date and installed on the host system
	- git
	- docker
	- docker-compose
	- [mkcert](https://github.com/FiloSottile/mkcert)
- Clone this repository
- Docker Hub login
	- There is a RO Docker Hub user in LP which should be available to all engineers.
	- `docker login`
- Add any host entries for the sites you want enable
	- `127.0.0.1 traefik.pmcdev.local`
	- `127.0.0.1 <theme_folder_name>.pmcdev.local`

- Start the proxy and setup environment
	- `. ./dev.sh && traefik up`
	- The traefik dashboard is at http://traefik.pmcdev.local:8080/dashboard/ or 0.0.0.0:8080
	- Once the traefik proxy is started you can run as many or as few projects as you want the general outline is in Proxied Sites

##  Proxied Sites
Each site to be proxied needs a valid configuration. Documentation for configuration is here: https://confluence.pmcdev.io/x/QIfJAQ

To launch a configured site the general process is:

	- cd <theme_dir>
	- docker-compose up -d
	- docker-compose run -v /path/to/ssh_rsa_privkey:/root/.ssh/id_rsa --rm pipeline-build
		- This step installs dependencies and sets up mysql db for project
		- Only need to run when installing or updating dependencies as well as building assets
		- @NOTE: The colon between your privkey and `/root/.ssh/id_rsa`
		- Path to a private key with bitbucket/github access -- don't use a password protected key, it's a pain
		- An SSH_AUTH_SOCK can also be used instead of an ssh key if you use a hardware key
	- docker-compose run --rm pipeline-test
		- Runs tests configured specific to environment of project
		- All env vars can be overriden via passing the `-e SOME_VAR=somval`

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

### Binding to a specific IP address
By default Traefik will bind to all interfaces - you can override this with the `PMC_DEV_BIND_IP` environment variable. If you change this you will need to update your host entries as well.

#### Add Additional Loopback Addresses on Mac OS
To add another loopback IP address on Mac, install the Launch Daemon from [contrib/io.pmcdev.ifconfig.plist](contrib/io.pmcdev.ifconfig.plist), and set `PMC_DEV_BIND_IP` to be `127.0.0.2` (or whatever IP you configure in the Launch Daemon).

### Issues & PRs
If there's something you don't see support for or needs more work please submit issues to DevOps or feel free to create your own PR

	- Please submit issues to (DevOps)[https://jira.pmcdev.io/secure/CreateIssueDetails!init.jspa?pid=11604&issuetype=7]
