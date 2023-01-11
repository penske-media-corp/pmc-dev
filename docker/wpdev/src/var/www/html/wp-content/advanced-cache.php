<?php

if ( ! defined ( 'WP_BATCACHE' ) || WP_BATCACHE ) {
	// VIP GO environment does not support batcache
	if ( ! defined( 'IS_VIP_GO' ) || ! IS_VIP_GO ) {
		if ( file_exists( __DIR__ . '/advanced-batcache.php' ) ) {
			require __DIR__ . '/advanced-batcache.php';
		}
	}
}
