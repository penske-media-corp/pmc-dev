<?php
$GLOBALS['pmc_trigger_error_exclude_list'] = [
	'Function create_function() is deprecated',
	'category_link',
	'vary_cache_on_function',
	'wpcom_vip_load_custom_cdn',
	'wpcom_vip_load_plugin',
];

add_filter( 'deprecated_constructor_trigger_error', '__return_false', 9999 );
add_filter( 'deprecated_function_trigger_error', '__return_false', 9999 );
add_filter( 'deprecated_hook_trigger_error', '__return_false', 9999 );

if ( defined( 'WP_DEBUG' ) && WP_DEBUG ) {

	set_error_handler( function( $errno, $errstr, $errfile = false, $errline = false, array $errcontext = [] ) {
		if (0 === error_reporting()) {
			return false;
		}
		if ( in_array( $errstr, $GLOBALS['pmc_trigger_error_exclude_list'], true ) ) {
			return true;
		}

		return false;

	}, E_DEPRECATED | E_USER_DEPRECATED );

}

add_filter( 'doing_it_wrong_trigger_error', function( $trigger_error, $function ) {
	if ( in_array( $function, $GLOBALS['pmc_trigger_error_exclude_list'], true ) ) {
		return false;
	}
	return $trigger_error;
}, 9999, 2 );
