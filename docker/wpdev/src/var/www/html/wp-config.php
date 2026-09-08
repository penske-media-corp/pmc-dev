<?php
/**
 * DO NOT make changes to this file. Add custom settings to wp-config/local-config.php
 * This file will get override when docker image replaced / rebuild
 */

if ( file_exists( __DIR__ . '/wp-functions.php' ) ) {
	require_once( realpath( __DIR__ . '/wp-functions.php' ) );
}

if (
	( isset( $_SERVER['HTTP_X_SSL_CIPHER'] ) )
	|| ( isset( $_SERVER['HTTPS'] ) && $_SERVER['HTTPS'] === 'on')
	|| ( isset( $_SERVER['HTTP_X_FORWARDED_PROTO'] ) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https')
) {
	$_SERVER['HTTPS'] = 'on';
	$_SERVER['HTTP_X_FORWARDED_PROTO'] = 'https';
	$_SERVER['HTTP_PROTO'] = 'https';
	define( 'HTTP_PROTO', 'https' );
}
else {
	define( 'HTTP_PROTO', 'http' );
}

/**
 * Local mods
 */

if ( file_exists( __DIR__ . '/wp-config/local-config.php' ) ) {
	require __DIR__ . '/wp-config/local-config.php';
}

if ( file_exists( __DIR__ . '/wp-config/bootstrap.php' ) ) {
	require __DIR__ . '/wp-config/bootstrap.php';
}

ifndef('WP_CACHE_KEY_SALT', strtolower( $_SERVER['HTTP_HOST'] ) );
ifdefenv( 'WP_CACHE', false );

ifdefenv( 'DB_HOST', 'mysql' );
ifdefenv( 'DB_NAME', 'wordpress');
ifdefenv( 'DB_USER', 'root' );
ifdefenv( 'DB_PASSWORD', '' );

ifndef( 'DB_CHARSET', 'utf8' );
ifndef( 'DB_COLLATE', '' );

/** Enable Automatic core updates. */
ifndef( 'WP_AUTO_UPDATE_CORE', true );

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each a unique
 * prefix. Only numbers, letters, and underscores please!
 */
$table_prefix = 'wp_';

/**
 * WordPress Localized Language, defaults to English.
 *
 * Change this to localize WordPress. A corresponding MO file for the chosen
 * language must be installed to wp-content/languages. For example, install
 * de_DE.mo to wp-content/languages and set WPLANG to 'de_DE' to enable German
 * language support.
 */
ifndef( 'WPLANG', '' );

ifdefenv( 'WP_DEBUG', false );
ifndef( 'SAVEQUERIES', false );

ifdefenv( 'JETPACK_DEV_DEBUG', false );

/* Content Directory */
ifndef( 'WP_CONTENT_DIR', __DIR__ . '/wp-content' );
ifndef( 'WP_PLUGIN_DIR', WP_CONTENT_DIR . '/plugins' );

ifndef( 'WP_CONTENT_URL', HTTP_PROTO . '://' . $_SERVER['HTTP_HOST'] . '/wp-content' );

ifndef( 'WP_ALLOW_MULTISITE', ( getenv('WP_ALLOW_MULTISITE') ? : false ) );
ifndef( 'MULTISITE', ( getenv('MULTISITE') ? : false ) );
ifndef( 'SUNRISE', ( getenv('SUNRISE') ? : false ) );

ifndef( 'PATH_CURRENT_SITE', '/' );
ifndef( 'SITE_ID_CURRENT_SITE', 1 );
ifndef( 'BLOG_ID_CURRENT_SITE', 1 );

ifndef( 'DOMAIN_CURRENT_SITE', $_SERVER['HTTP_HOST'] );
ifndef( 'SUBDOMAIN_INSTALL', false );
ifndef( 'WP_DEFAULT_THEME', 'twentysixteen' );
ifndef( 'ABSPATH', dirname( __FILE__ ) . '/wordpress/' );

if ( file_exists( __DIR__ . '/wp-config/batcache-config.php' ) ) {
	require __DIR__ . '/wp-config/batcache-config.php';
}

if ( class_exists( \WP\Config\Bootstrap::class ) ) {
	\WP\Config\Bootstrap::get_instance()->start();
}

/** Sets up WordPress vars and included files. */
require_once( ABSPATH . 'wp-settings.php' );

