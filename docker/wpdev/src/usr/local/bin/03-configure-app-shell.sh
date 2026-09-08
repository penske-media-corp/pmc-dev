#!/bin/bash

. <( cat /usr/local/bin/*-functions.sh )

provision_local_tgz /root root

setup-phpcs

if [[ true == "${PMC_PATCH_WPTEST}" ]]; then
  if [[ -z "$(grep "this->__setUp_called" /var/www/html/wp-tests/tests/phpunit/includes/abstract-testcase.php)" ]]; then
    sed -e "/protected function assertPostConditions() {/a \\\t\tif ( empty( \$this->__setUp_called ) ) {\n\t\t\tthrow new \\\\Error( sprintf( 'The unit test class %s did not extends \\\\PMC\\\\Unit_Test\\\\Base abstract class properly', static::class ) );\n\t\t}" -i /var/www/html/wp-tests/tests/phpunit/includes/abstract-testcase.php
  fi
fi

# backward compatible constant
if [[ -z "${DB_NAME}" ]]; then
  export DB_NAME="${DB_DATABASE}"
fi

if [[ -z "${DB_USERNAME}" ]]; then
  export DB_USERNAME="${DB_USER}"
fi

maybe_start_mysql
maybe_create_db "${DB_HOST}" "${DB_USERNAME}" "${DB_PASSWORD}" "${DB_NAME}"
maybe_create_db "${TEST_DB_HOST}" "${TEST_DB_USERNAME}" "${TEST_DB_PASSWORD}" "${TEST_DB_NAME}"

if [[ -n "${PHPUNIT_BIN}" && -f "${PHPUNIT_BIN}" && "${PHPUNIT_BIN}" != "/usr/bin/phpunit" ]]; then
  ln -sf ${PHPUNIT_BIN} /usr/bin/phpunit
fi
