<?php
global $wpdb;

// We want to suppress the db errors to prevent warnings message clustering the unit test / core install during wp setups.
if ( ( defined('IS_UNIT_TEST') && IS_UNIT_TEST ) || ( defined( 'WP_INSTALLING' ) && WP_INSTALLING ) ) {
	if ( empty($wpdb) && class_exists('wpdb') ) {
		$wpdb = new wpdb(DB_USER, DB_PASSWORD, DB_NAME, DB_HOST);
	}
	if ( ! empty( $wpdb ) ) {
		$wpdb->suppress_errors(true);
	}
}
