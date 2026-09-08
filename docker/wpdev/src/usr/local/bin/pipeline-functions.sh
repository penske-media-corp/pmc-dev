#!/bin/bash

function maybe_start_mysql() {
  if [[ -n "$(service --status-all 2>&1 | grep mysql)" && -z "$(service --status-all 2>&1 | grep mysql | grep -)" ]]; then
    usermod -d /var/lib/mysql/ mysql
    chown -R mysql:mysql /var/lib/mysql
    service mysql start
  fi
}

function maybe_create_db() {
  DB_HOST="$1"
  DB_USER="$2"
  DB_PASS="$3"
  DB_NAME="$4"

  if [[ -z "${DB_NAME}" || -z "{$DB_HOST}" || -z "${DB_USER}" ]]; then
    return
  fi
  PARAM=""
  if [[ -n "${DB_PASS}" ]]; then
    PARAM="${PARAM} -p${DB_PASS}"
  fi
  mysql $PARAM -u${DB_USER} -h${DB_HOST} -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
}

function git_switch_to_master_if_branch_not_exist {
  local BRANCH="$1"
  local FOLDER="$2"

  if [[ -n "${FOLDER}" ]]; then
    pushd ${FOLDER}
  fi

  if [[ -d .git ]]; then
    GIT_REMOTE="$(git remote -v | grep -m 1 -E "origin.*fetch" | sed -e 's/\t/ /g' -e 's/\s+/ /g' | cut -d' ' -f2)"
    REMOTE_BRANCH="$(git ls-remote --heads ${GIT_REMOTE} 2>/tmp/stderr | grep -Ei "heads/${BRANCH}\$" | awk -F'refs/heads/' '{ print $2 }')"
    git fetch
    if [[ -n "${REMOTE_BRANCH}" ]]; then
      git checkout ${BRANCH}
    else
      git checkout master
    fi
    git pull
  fi

  if [[ -n "${FOLDER}" ]]; then
    popd
  fi

}

function maybe_switch_branch_for_testing_theme {
  local THEME="$1"
  local BRANCH="$2"

  export WP_THEME_PARENT=
  export WP_THEME_PARENT_BRANCH=
  export PMC_PLUGINS_BRANCH=

  if [[ -z "${BRANCH}" ]]; then
    if [[ -n "${THEME}" && "." != "${THEME}" ]]; then
      if [[ ! -d ${WP_THEME_FOLDER}/${THEME}/.git || ! -f ${WP_THEME_FOLDER}/${THEME}/style.css ]]; then
        return
      fi
      pushd ${WP_THEME_FOLDER}/${THEME}
      BRANCH="$(git rev-parse --abbrev-ref HEAD)"
      popd
    elif [[ -d .git && -f style.css ]]; then
      BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    fi
  fi

  if [[ -z "${BRANCH}" ]]; then
    return;
  fi

  # Detecting wp parent theme
  echo "Detecting parent theme: ${THEME}"
  export WP_THEME_PARENT="$(get_parent_wp_theme "${THEME}")"

  # Detect wp parent theme matching branch
  if [[ -n "${WP_THEME_PARENT}" ]]; then
    echo "Switch branch '${BRANCH}' on parent theme '${WP_THEME_PARENT}'"
    pushd ${WP_THEME_FOLDER}/${WP_THEME_PARENT}
    git_switch_to_master_if_branch_not_exist "${BRANCH}"

    export WP_THEME_PARENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

    popd
  fi

  # Detect pmc-plugin matching branch
  if [[ -d ${WP_THEME_FOLDER}/pmc-plugins ]]; then
    echo "Switch branch '${BRANCH}' on 'pmc-plugins'"
    pushd ${WP_THEME_FOLDER}/pmc-plugins
    git_switch_to_master_if_branch_not_exist "${BRANCH}"
    export PMC_PLUGINS_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    popd
  elif [[ -d ${WEB_ROOT}/wp-content/plugins/pmc-plugins ]]; then
    echo "Switch branch '${BRANCH}' on 'pmc-plugins'"
    pushd ${WEB_ROOT}/wp-content/plugins/pmc-plugins
    git_switch_to_master_if_branch_not_exist "${BRANCH}"
    export PMC_PLUGINS_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
    popd
  fi

  # In production, we always use master for this vip/vipgo plugins
  # Added for backward compatible with existing pipeline that use composer to install these plugins that maybe out of sync
  if [[ -d ${WEB_ROOT}/wp-content/plugins/pmc-vip-go-plugins ]]; then
    pushd ${WEB_ROOT}/wp-content/plugins/pmc-vip-go-plugins
    git_switch_to_master_if_branch_not_exist "master"
    popd
    . pmc-functions && pmc_composer_post_install vipgo
  elif [[ -d ${WEB_ROOT}/wp-content/plugins/wordpress-vip-plugins ]]; then
    pushd ${WEB_ROOT}/wp-content/plugins/wordpress-vip-plugins
    git_switch_to_master_if_branch_not_exist "master"
    popd
    . pmc-functions && pmc_composer_post_install wpcom
  fi

}

function maybe_build_pmc_plugins_js_checklist {
  IFS=$'\n';
  echo -e "PMC_PLUGINS_JS_CHECKLIST:\n ${PMC_PLUGINS_JS_CHECKLIST[*]}"
  echo -e "JS_FILES:\n ${JS_FILES[*]}"

  if [[ -n "${PMC_PLUGINS_JS_CHECKLIST}" || -z "${JS_FILES}" || 'pmc-plugins' != "${REPO_SLUG}" ]]; then
    return
  fi

  PMC_PLUGINS_JS_CHECKLIST=()
  # Loop through changed js files in commit
  for i in "${JS_FILES[@]}"
    do
      # Build array of unique directories from git
      BASE_PLUGIN_DIRECTORY=$(echo "${i}" | cut -d "/" -f1)
      # Check if directory is already in array and if not add it to the array
      if [[ ! " ${PMC_PLUGINS_JS_CHECKLIST[@]} " =~ " ${BASE_PLUGIN_DIRECTORY} " ]]
        then
          echo -e "${BLUE}${INFO}${RESET} Adding directory ${LIGHT_RED}${BASE_PLUGIN_DIRECTORY}${RESET} to build js check list"
          PMC_PLUGINS_JS_CHECKLIST+=("${BASE_PLUGIN_DIRECTORY}")
      fi
  done

  export PMC_PLUGINS_JS_CHECKLIST=${PMC_PLUGINS_JS_CHECKLIST}
  export PMC_IS_PMC_PLUGINS=true

}

function maybe_copy_artifacts {
  if  [[ -z ${PMC_ARTIFACTS} || false == ${PMC_ARTIFACTS} ]]
    then
      return
  fi
  if [[ true == ${PMC_ARTIFACTS} ]]
    then
      if [[ $PWD =~ pmc-plugins/ ]]
        then
          PMC_ARTIFACTS=${PWD%/*}/artifacts
        else
          PMC_ARTIFACTS=${PWD}/artifacts
      fi
  fi
  mkdir -p $PMC_ARTIFACTS
  cp $1 $PMC_ARTIFACTS
  echo "copy artifacts: $1 -> $PMC_ARTIFACTS"
}

function checkout_dependencies {
  local THEME="$1"

  if [[ -n "${THEME}" && "." != "${THEME}" ]]; then
    if [[ -f ${WP_THEME_FOLDER}/${THEME}/style.css ]]; then
      THEME_STYLE=${WP_THEME_FOLDER}/${THEME}/style.css
    fi
  elif [[ -f style.css ]]; then
    THEME_STYLE=$(pwd)/style.css
  fi

  if [[ ! -f ${THEME_STYLE} ]]; then
    return
  fi

  THEME_PARENT=$(cat ${THEME_STYLE}  | grep Template: | awk -F"\: *" '{print $2}')
  if [[ -n "${THEME_PARENT}" ]]; then
    if [[ "${THEME_PARENT}" == vip/* ]]; then
      THEME_PARENT=$(echo "${THEME_PARENT}" | cut -d'/' -f2)
      git_checkout ${WP_THEME_FOLDER}/vip/${THEME_PARENT} git@github.com:penske-media-corp/${THEME_PARENT}.git 0
    else
      git_checkout ${WP_THEME_FOLDER}/${THEME_PARENT} git@github.com:penske-media-corp/${THEME_PARENT}.git 0
    fi
  fi
  git_checkout ${WEB_ROOT}/wp-content/plugins/pmc-plugins git@github.com:penske-media-corp/pmc-plugins.git 0

}

function patch_phpcs {
  if [[ -z "$(grep "self::getConfigData('show_sources')" ./vendor/squizlabs/php_codesniffer/src/Config.php)" ]]; then
    sed "/self::getConfigData('show_progress')/i\$showSources=self::getConfigData('show_sources');if(\$showSources!==null){\$this->showSources=(bool)\$showSources;}"  -i vendor/squizlabs/php_codesniffer/src/Config.php
    echo "Patched phpcs"
  fi
}
