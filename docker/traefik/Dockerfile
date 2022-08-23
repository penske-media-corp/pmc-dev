ARG CERT_FILE=wildcard.pmcdev.local
ARG CERT_DOMAIN="*.pmcdev.local *.wpvipgo.local *.wpvip.local *.local *.service"

FROM ubuntu:18.04 as BUILD

ARG CERT_DOMAIN
ARG CERT_FILE

ENV DEBIAN_FRONTEND=noninteractive
ENV MKCERT_VERSION=1.3.0
ENV CAROOT=/build/certs/mkcert
ENV CERT_FILE="${CERT_FILE}"
ENV CERT_DOMAIN="${CERT_DOMAIN}"

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
	&& curl https://github.com/FiloSottile/mkcert/releases/download/v${MKCERT_VERSION}/mkcert-v${MKCERT_VERSION}-linux-amd64 --location -o /usr/local/bin/mkcert \
	&& ln -fs /usr/local/bin/mkcert /usr/bin/mkcert \
	&& chmod +x /usr/local/bin/* \
	&& mkdir -p /build/etc /build/certs ${CAROOT} \
	&& mkcert -install

RUN mkcert -cert-file "/build/certs/${CERT_FILE}.cert.pem" -key-file "/build/certs/${CERT_FILE}.key.pem" ${CERT_DOMAIN}

ADD etc/ /build/etc/

FROM traefik:1.7.16-alpine
MAINTAINER Hau Vong <hvong@pmc.com>

COPY --from=BUILD /build/ /
