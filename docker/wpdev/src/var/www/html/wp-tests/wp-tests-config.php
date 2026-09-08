<?php
/**
 * DO NOT make changes to this file. Add custom settings to wp-config/local-config-tests.php
 * This file will get override when docker image replaced / rebuild
 */

$_SERVER['HTTP_USER_AGENT'] = 'phpunit test';

if ( file_exists( __DIR__ . '/../wp-functions.php' ) ) {
	require_once( realpath( __DIR__ . '/../wp-functions.php' ) );
}

ifndef( 'IS_UNIT_TEST', true );
ifndef( 'WP_BATCACHE', false );

/*
 * Support local test config override
 */
if ( file_exists( __DIR__ . '/../wp-config/local-config-tests.php' ) ) {
	require_once( __DIR__ . '/../wp-config/local-config-tests.php' );
}

if ( file_exists( __DIR__ . '/../wp-config/bootstrap.php' ) ) {
	require_once realpath( __DIR__ . '/../wp-config/bootstrap.php' );
}

ifdefenv( 'WEB_ROOT', '/var/www/html' );
ifndef( 'ABSPATH', WEB_ROOT . '/wordpress/' );

/*
 * Path to the theme to test with.
 *
 * The 'default' theme is symlinked from test/phpunit/data/themedir1/default into
 * the themes directory of the WordPress install defined above.
 */
ifndef('WP_DEFAULT_THEME', 'default');

// Test with multisite enabled.
// Alternatively, use the tests/phpunit/multisite.xml configuration file.
// define( 'WP_TESTS_MULTISITE', true );

// Force known bugs to be run.
// Tests with an associated Trac ticket that is still open are normally skipped.
// define( 'WP_TESTS_FORCE_KNOWN_BUGS', true );

// Test with WordPress debug mode (default).
ifndef('WP_DEBUG', true);

// ** MySQL settings ** //

// This configuration file will be used by the copy of WordPress being tested.
// wordpress/wp-config.php will be ignored.

// WARNING WARNING WARNING!
// These tests will DROP ALL TABLES in the database with the prefix named below.
// DO NOT use a production database or one that is shared with something else.

if ( getenv( 'TEST_TOKEN' ) !== false ) {
	ifdefenv('DB_NAME', 'wptests_' . getenv( 'TEST_TOKEN' ), 'TEST_DB_NAME' );
} else {
	ifdefenv('DB_NAME', 'wptests', 'TEST_DB_NAME' );
}

ifdefenv('DB_USER', 'root', 'TEST_DB_USER' );
ifdefenv('DB_PASSWORD', '', 'TEST_DB_PASSWORD' );
ifdefenv('DB_HOST', 'localhost', 'TEST_DB_HOST' );

ifndef('DB_CHARSET', 'utf8');
ifndef('DB_COLLATE', '');

/*
 * We're doing unit test, no need to generate complex key here
 */
ifndef('AUTH_KEY', DB_NAME);
ifndef('SECURE_AUTH_KEY', DB_NAME);
ifndef('LOGGED_IN_KEY', DB_NAME);
ifndef('NONCE_KEY', DB_NAME);
ifndef('AUTH_SALT', DB_NAME);
ifndef('SECURE_AUTH_SALT', DB_NAME);
ifndef('LOGGED_IN_SALT', DB_NAME);
ifndef('NONCE_SALT', DB_NAME);

if ( empty( $table_prefix) ) {
	$table_prefix = 'wptests_';
}

ifndef('WP_TESTS_DOMAIN', 'pmcdev.local');
ifndef('WP_TESTS_EMAIL', 'admin@pmcdev.local');
ifndef('WP_TESTS_TITLE', 'Test Blog');

ifndef('WP_PHP_BINARY', 'php');

ifndef('WPLANG', '');

ifndef( 'WP_CONTENT_DIR', WEB_ROOT . '/wp-content' );
ifndef( 'WP_PLUGIN_DIR', WP_CONTENT_DIR . '/plugins' );

if ( class_exists( \WP\Config\Bootstrap::class ) ) {
	\WP\Config\Bootstrap::get_instance()->start();
}
