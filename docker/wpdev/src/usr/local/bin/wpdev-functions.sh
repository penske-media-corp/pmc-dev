#!/bin/bash

declare -a ERRORS

if [[ -z "${WP_THEME_FOLDER}" ]]; then
  if [[ -z "${WEB_ROOT}" ]]; then
    export WEB_ROOT=/var/www/html
  fi
  export WP_THEME_FOLDER="${WEB_ROOT}/wp-content/themes"
fi

function echo_error {
  local PREFIX="ERROR: "

  if [ "0" == "$2" ]; then
    PREFIX=""
  fi

  printf "\e[1m\e[31m${PREFIX}${1}\e[0m\n" 1>&2

  ERRORS[${#ERRORS[*]}]=${1}
}

function echo_warning {
  local PREFIX="WARNING: "

  if [ "0" == "$2" ]; then
    PREFIX=""
  fi

  printf "\e[33m${PREFIX}${1}\e[0m\n" 1>&2

}

function echo_warning2 {
  local PREFIX="WARNING: "

  if [ "0" == "$2" ]; then
    PREFIX=""
  fi

  printf "\e[1m\e[31m${PREFIX}${1}\e[0m\n" 1>&2

}

function echo_ok {
  local PREFIX="OK: "

  if [ "0" == "$2" ]; then
    PREFIX=""
  fi

  printf "\e[1m\e[32m${PREFIX}${1}\e[0m\n" 1>&2
}

function echo_info {
  printf "\e[32m${1}\e[0m\n" 1>&2
}

function git_checkout {
  local TARGET=${1}
  local SOURCE=${2}
  local DEPTH=${3}

  if [[ ! "${SOURCE}" =~ \@ ]]; then
    echo_error 'Unknown git repository "%{SOURCE}"'
    return 1
  fi

  echo_info "git_checkout ${TARGET}"
  mkdir -p ${TARGET}
  pushd ${TARGET}
  setup_ssh_agent
  git config --global --add safe.directory $( pwd )
  if [ ! -d .git ]; then
    TMP_DIR=$(mktemp -d -t git-checkout-XXXXXXXXXX)
    if [[ -z "${DEPTH}" || "0" == "${DEPTH}" ]]; then
      git clone --recursive -n --separate-git-dir .git ${SOURCE} ${TMP_DIR}
    else
      git clone --depth ${DEPTH} -n --separate-git-dir .git --branch=master ${SOURCE} ${TMP_DIR}
    fi
    rm -rf ${TMP_DIR}
    git reset --hard
  else
    git pull
  fi
  popd

  if [ -d ${TARGET}/.git ]; then
    echo_ok "${TARGET}\n"
  else
    echo_error "${TARGET}"
  fi
}

function bitbucket_checkout {
  local TARGET=${1}
  local SOURCE=${2}
  local DEPTH=${3}

  if [[ ! "${SOURCE}" =~ \@ ]]; then
    SOURCE=git@github.com:penske-media-corp/${2}.git
  fi

  git_checkout "${TARGET}" "${SOURCE}" "${DEPTH}"
}

function github_checkout {
  local TARGET=${1}
  local SOURCE=${2}
  local DEPTH=${3}

  if [[ ! "${SOURCE}" =~ \@ ]]; then
    SOURCE=git@github.com:penske-media-corp/${2}.git
  fi

  git_checkout "${TARGET}" "${SOURCE}" "${DEPTH}"
}

function zip_install {
  local TARGET=${1}
  local SOURCE=${2}
  mkdir -p "${TARGET}"
  curl -sL "${SOURCE}" | bsdtar -C "${TARGET}" -xvf-
}

function tgz_install {
  local TARGET=${1}
  local SOURCE=${2}
  mkdir -p "${TARGET}"
  curl -sL ${SOURCE} | tar --totals --checkpoint=.1000 -xz --directory="${TARGET}"
}

function get_parent_wp_theme {
  local THEME="$1"
  if [[ -z "${THEME}" || "." == "${THEME}" ]]; then
    local CSS_FILE="$(pwd)/style.css"
  else
    local CSS_FILE="${WP_THEME_FOLDER}/${THEME}/style.css"
  fi
  if [[ -f ${CSS_FILE} ]]; then
    local P_THEME="$(grep "Template:" ${CSS_FILE} | tr "\n\r" "  " | sed -e 's/.*Template:\s*\|vip\/\|\s*//g')"
    if [[ -f ${WP_THEME_FOLDER}/${P_THEME}/style.css ]]; then
      echo "${P_THEME}"
    elif [[ -f ${WP_THEME_FOLDER}/vip/${P_THEME}/style.css ]]; then
      echo "vip/${P_THEME}"
    fi
  fi
}

function checkout_wp_web_root {
  local THEME="$1"

  if [[ -n "${THEME}" ]]
  then
    JSON_FILE="${WP_THEME_FOLDER}/${THEME}/.pmc-dev.json"
  elif [[ -f .pmc-dev.json ]]
  then
    JSON_FILE=".pmc-dev.json"
  fi

  if [[ -z "${JSON_FILE}" || ! -f "${JSON_FILE}" ]]
  then
    return
  fi

  for folder in $(jq -r '.WEB_ROOT | keys[]' ${JSON_FILE})
  do

    for type in $(jq -r ".WEB_ROOT.\"${folder}\" | keys[]" ${JSON_FILE})
    do
      for source in $(jq -r ".WEB_ROOT.\"${folder}\".\"${type}\" | keys[]" ${JSON_FILE})
      do
        target=$(jq -r ".WEB_ROOT.\"${folder}\".\"${type}\".\"${source}\".target" ${JSON_FILE})

        FOLDER_TYPE="${WEB_ROOT}/${folder}/${type}"

        if [[ "${source}" =~ git@ ]]
        then
          git_checkout "${FOLDER_TYPE}/${target}" "${source}"
        elif [[ "${source}" =~ .zip ]]
        then
          zip_install "${FOLDER_TYPE}/${target}" "${source}"
        elif [[ "${source}" =~ .tgz ]]
        then
          tgz_install "${FOLDER_TYPE}/${target}" "${source}"
        fi

        if [[ -n "${target}" && "." != "${target}" && -d ${FOLDER_TYPE}/${target} ]]
        then
          if [[ "null" != "$(jq -r ".WEB_ROOT.\"${folder}\".\"${type}\".\"${source}\".links" ${JSON_FILE})" ]]
          then
            for i in $(jq -r ".WEB_ROOT.\"${folder}\".\"${type}\".\"${source}\".links | keys[]" ${JSON_FILE})
            do
              link=$(jq -r ".WEB_ROOT.\"${folder}\".\"${type}\".\"${source}\".links[${i}]" ${JSON_FILE})
              ln -sf "${FOLDER_TYPE}/${target}/${link}" "${FOLDER_TYPE}/${link}"
            done
          fi
        fi

      done
    done

  done
}

function checkout_wp_theme  {
  local THEME="$1"
  bitbucket_checkout ${WP_THEME_FOLDER}/${THEME} ${THEME} 0

  if [[ ! -d ${WP_THEME_FOLDER}/${THEME}/.git ]]; then
    return
  fi

  pushd ${WP_THEME_FOLDER}/${THEME}

  # We need to also checkout any parent theme as dependencies
  local PARENT_THEME="$(get_parent_wp_theme "${THEME}")"
  if [[ -n "${PARENT_THEME}" && ! -f ${WP_THEME_FOLDER}/${PARENT_THEME}/style.css ]]; then
    bitbucket_checkout ${WP_THEME_FOLDER}/${PARENT_THEME} ${PARENT_THEME} 0
  fi

  # We need to checkout the project plugins dependencies
  checkout_wp_web_root "${THEME}"

  popd

}

function provision_git {

  if [[ "$GITHUB_AUTHENTICATED" = false ]]; then
    echo "github is not authenticated."
    return
  fi

  local TARGET="${1}"
  local REPO="${2}"
  local BRANCH="${3}"
  local MAYBE_PROVISION=yes
  local PACKAGE=$(basename -s .git ${REPO})

  if [[ -z "${BRANCH}" ]]; then
    BRANCH="main"
  fi

  mkdir -p ${TARGET}
  if [[ ! -w ${TARGET} ]]; then
    echo "Cannot provision readonly folder: ${TARGET}"
    return
  fi

  setup_ssh_agent

  pushd ${TARGET}
  git config --global --add safe.directory $( pwd )

  rm -f /tmp/.version-provision-git
  git ls-remote ${REPO} HEAD | awk '{ print $1 }' > /tmp/.version-provision-git
  if [[ -z "$(cat /tmp/.version-provision-git )" ]]; then
    echo "Cannot locate repository: ${REPO}"
    return
  fi

  echo "${PACKAGE}: Remote  - $(cat /tmp/.version-provision-git)"

  if [[ -f .version.${PACKAGE} ]]; then
    echo "${PACKAGE}: Current - $(cat .version.${PACKAGE})"
    if [[ "$(cat /tmp/.version-provision-git)" == "$(cat .version.${PACKAGE})" ]]; then
      MAYBE_PROVISION=no
    fi
  fi

  if [[ "yes" = "${MAYBE_PROVISION}" ]]; then
    if [[ ! -d .git ]]; then
      if [[ -z "$(ls -1qA ./)" ]]; then
        git clone --depth 1 --branch=${BRANCH} ${REPO} .
      else
        TMP_DIR=$(mktemp -d -t provision-git-XXXXXXXXXX)
        git clone --depth 1 -n --separate-git-dir .git --branch=${BRANCH} ${REPO} ${TMP_DIR}
        rm -rf ${TMP_DIR}
        git reset --hard
      fi
    else
      git reset --hard
      git pull
      git submodule update --init
    fi
    git rev-parse HEAD > .version.${PACKAGE}
  fi

  popd
}

function setup_ssh_agent() {

  mkdir -p $HOME/.ssh

  if [[ -f /run/secrets/ssh_key || -n "${SSH_ENCODED_KEY}" ]]; then

    echo "Attempting to setup ssh key in docker container"

    if [[ -z "${SSH_AUTH_SOCK}" && -f /.ssh-agent.env ]]; then
      . /.ssh-agent.env
    fi

    ssh-add -l
    if [[ $? -eq 2 ]]; then
      if [[ -n "${SSH_AUTH_SOCK}" ]]; then
        if [[ -e ${SSH_AUTH_SOCK} ]]; then
          rm -f ${SSH_AUTH_SOCK}
        fi
        ssh-agent -a ${SSH_AUTH_SOCK}
      fi

      ssh-add -l
      if [[ $? -eq 2 ]]; then
        eval `ssh-agent`
        echo "export SSH_AUTH_SOCK=${SSH_AUTH_SOCK}" > /.ssh-agent.env
      fi
    fi

    if [[ -f /run/secrets/ssh_key ]]; then
      cat /run/secrets/ssh_key | ssh-add -
    fi

    if ( echo "${SSH_ENCODED_KEY}" | grep -q "KEY--" ); then
        echo "${SSH_ENCODED_KEY}" | ssh-add -
    else
        echo "${SSH_ENCODED_KEY}" | base64 -di | ssh-add -
    fi

    ssh-add -l

  fi

}
