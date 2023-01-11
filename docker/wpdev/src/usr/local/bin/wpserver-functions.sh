#!/bin/bash

function provision_local_tgz {
  local TARGET="${1}"
  local PACKAGE="${2}"
  local SOURCE="/usr/local/src"
  local MAYBE_PROVISION=yes
  local PROVISION_NAME=local

  if [[ ! -f ${SOURCE}/${PACKAGE}.tgz ]]; then
    return
  fi

  mkdir -p ${TARGET}
  if [[ ! -w ${TARGET} ]]; then
    echo "Cannot provision readonly folder: ${TARGET}"
    return;
  fi

  cd ${TARGET}

  if [[ -f .version.${PACKAGE}-${PROVISION_NAME} ]]; then
    echo "${PACKAGE}: Source  - $(cat ${SOURCE}/${PACKAGE}.version)"
    echo "${PACKAGE}: Current - $(cat .version.${PACKAGE}-${PROVISION_NAME})"
    if [[ "$(cat ${SOURCE}/${PACKAGE}.version)" == "$(cat .version.${PACKAGE}-${PROVISION_NAME})" ]]; then
      MAYBE_PROVISION=no
    fi
  fi

  if [[ "yes" = "${MAYBE_PROVISION}" ]]; then
    echo "Extracting package ${PACKAGE}.tgz"
    flock -w 30 . tar --totals --checkpoint=.1000 -xzf ${SOURCE}/${PACKAGE}.tgz
    cp ${SOURCE}/${PACKAGE}.version .version.${PACKAGE}-${PROVISION_NAME}
  fi

}

function build_local_tgz {
  local TARGET="${1}"
  local PACKAGE="${2}"
  local SOURCE="${3}"
  local BUILT="${4}"

  if [[ -z "${BUILT}" ]]; then
    BUILT="$(date +"%Y-%m-%d@%T")"
  fi

  provision_local_tgz "${TARGET}" "${PACKAGE}"

  mkdir -p ${TARGET}
  cd ${TARGET}
  rm -f .version.*
  echo "Package built ${BUILT} - php${PHP_VERSION}-wp${WP_VERSION}" > .version.${PACKAGE}

  mkdir -p ${SOURCE}
  tar -zcf ${SOURCE}/${PACKAGE}.tgz .
  cp .version.${PACKAGE} ${SOURCE}/${PACKAGE}.version
  rm -rf ${TARGET}
}
