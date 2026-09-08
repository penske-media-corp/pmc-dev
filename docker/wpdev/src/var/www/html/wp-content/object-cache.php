<?php

if ( file_exists( __DIR__ . '/object-memcached.php' ) ) {
	require __DIR__ . '/object-memcached.php';

	// During unit test & installation, we really want to flush the memcache if it is active
	if ( ( defined('IS_UNIT_TEST') && IS_UNIT_TEST )  || ( defined( 'WP_INSTALLING' ) && WP_INSTALLING ) ){
		wp_cache_init();
		wp_cache_flush();
	}

}
