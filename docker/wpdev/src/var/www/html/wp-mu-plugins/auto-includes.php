<?php
/**
 * This file should be symlink to the related VIP GO / Other mu-plugins folder
 */

// Controlling whether we want to load all plugins or not.
if ( defined( 'WP_MUPLUGINS_AUTO_INCLUDES') ) {
	return;
}

define( 'WP_MUPLUGINS_AUTO_INCLUDES', true );
$files = glob( __DIR__ . '/*.php' );
foreach ( $files as $fn ) {
	$fn = realpath( $fn );
	if ( file_exists( $fn ) ) {
		require_once ($fn);
	}
}
