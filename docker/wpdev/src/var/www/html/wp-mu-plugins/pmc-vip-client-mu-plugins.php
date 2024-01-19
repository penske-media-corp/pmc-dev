<?php
// Load plugins from theme client-mu-plugins folder
add_action( 'muplugins_loaded', function() {

	// this function should have been loaded on vip-go in mu-plugins event
	if ( ! function_exists('wpcom_vip_load_plugin') ) {
		return;
	}

	// Mirror production treatment of `client-mu-plugins` as best we can.
	// Cannot use `STYLESHEETPATH` as it isn't set yet.
	$theme_plugins_path = get_stylesheet_directory() . '/client-mu-plugins/';

	if ( wpcom_vip_should_load_plugins() && is_dir( $theme_plugins_path ) ) {
		foreach ( wpcom_vip_get_client_mu_plugins( $theme_plugins_path ) as $client_mu_plugin ) {
			include_once $client_mu_plugin;
		}

		unset( $client_mu_plugin );
	}

	unset( $theme_plugins_path );
});
