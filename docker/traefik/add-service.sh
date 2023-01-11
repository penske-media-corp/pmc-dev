#!/bin/sh

CONF_PATH="$(dirname $0)/conf/"
echo $CONF_PATH
exit
DOMAIN=$1
SERVICE_NAME=$2
SERVICE_PORT=$3
FILENAME=$4

if [ -z ${SERVICE_NAME} ]
then
  echo "Usage: $0 <domain> <service-name> [service-port] [filename]"
  exit 1
fi

if [ -z ${FILENAME} ]
then
  FILENAME=${SERVICE_NAME}
fi

CONF_FILENAME=${CONF_PATH}${FILENAME}.yml

FOUND_FILENAME=$(grep -l "rule: \"Host(\`${DOMAIN}\`)\"" ${CONF_PATH}*.yml)

if [ ! -z ${FOUND_FILENAME} ]
then
  echo "\"${DOMAIN}\" already found in file ${FOUND_FILENAME}"
  echo "Make sure to add following entry to /etc/hosts file:"
  echo "   127.0.0.1 ${DOMAIN}"
  exit 1;
fi

if [ ! -z ${SERVICE_PORT} ]
then
  SERVICE_PORT=":${SERVICE_PORT}"
fi

(cat <<EOT
http:
  routers:
    ${SERVICE_NAME}:
      entryPoints:
        - websecure
      rule: "Host(\`${DOMAIN}\`)"
      service: ${SERVICE_NAME}
      tls:
        certresolver: file

  services:
    ${SERVICE_NAME}:
      loadBalancer:
        servers:
          - url: "http://${SERVICE_NAME}${SERVICE_PORT}"
EOT
) >> ${CONF_FILENAME}

echo "New service \"${DOMAIN}\" added to file \"${CONF_FILENAME}\""
echo "Run \"docker-compose up -d --build nginx\" to restart nginx"
echo "Make sure to add following entry to /etc/hosts file:"
echo "   127.0.0.1 ${DOMAIN}"
