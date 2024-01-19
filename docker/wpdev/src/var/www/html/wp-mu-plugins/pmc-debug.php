<?php

if ( isset( $_GET['debug'] ) ) {
	error_reporting( E_ALL );
	ini_set('display_errors', 1);

	if ( 'info' === $_GET['debug'] ) {
		echo '<pre>';
		printf( "DB_NAME: %s\n", DB_NAME );
		printf( "WP_CONTENT_DIR : %s\n", WP_CONTENT_DIR );
		printf( "WP_PLUGIN_DIR : %s\n", WP_PLUGIN_DIR );
		printf( "WPMU_PLUGIN_DIR : %s\n", WPMU_PLUGIN_DIR );
		print_r( $_SERVER );
		echo '</pre>';
	}
}
