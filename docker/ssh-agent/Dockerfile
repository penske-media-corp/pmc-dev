FROM ubuntu:18.04

ENV DEBIAN_FRONTEND=noninteractive
ENV SSH_AUTH_SOCK=/ssh/ssh-agent.sock

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		openssh-client \
	&& apt-get clean && rm -rf /var/lib/apt/lists/*

ADD /src/ /
RUN chmod +x /usr/local/bin/*

ENTRYPOINT /usr/local/bin/docker-entrypoint.sh
