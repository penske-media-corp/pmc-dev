<?php

add_filter( 'pmc_do_not_load_plugin', function( $status, $plugin, $folder, $version ) {

	$excludes = [
			'pmc-ndn',
			'jetpack-force-2fa',
			'new-device-notification',
			'vip-go-elasticsearch',
			'wpcom-elasticsearch',
		];

	if ( in_array( $plugin, $excludes ) ) {
		return true;
	}

	return $status;

}, 10, 4 );

add_filter( 'jetpack_get_default_modules', function( $modules ) {
	$modules = array_diff( $modules, [ 'vaultpress' ] );
	return $modules;
}, 99 );

// EOF