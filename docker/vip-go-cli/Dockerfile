ARG SSH_KEY

FROM node:lts-buster-slim

ARG SSH_KEY
ENV DEBIAN_FRONTEND="noninteractive"
ENV GIT_SSL_NO_VERIFY=1

RUN node --version && npm --version

RUN apt-get update \
	&& apt-get install -y --no-install-recommends --no-install-suggests -y -q \
		build-essential \
		git \
		libsecret-1-0 \
		libsecret-1-dev \
		ssh-client \
	&& mkdir -p ~/.ssh && touch ~/.ssh/known_hosts && ssh-keygen -R github.com \
	&& echo "Host github.com \nStrictHostKeyChecking no \nUserKnownHostsFile=/dev/null\n" > ~/.ssh/config \
	&& npm install --unsafe-perm -g @automattic/vip \
	&& apt-get -y remove git ssh-client build-essential \
	&& apt-get clean && apt-get autoremove -y && apt-get autoclean -y && rm -rf /var/lib/apt/lists/*

ENTRYPOINT /usr/local/bin/vip
