<?php
namespace PMC\Mu_Plugin;

/**
 * This plugin is responsible to add any filters required to work for local wp dev
 * eg. fixing plugins_url function due to VIP Go vs Other plugins location
 */

class Filters {
	private static $_instance = null;
	public static function get_instance() {
		if ( empty( static::$_instance ) ) {
			static::$_instance = new static();
		}
		return static::$_instance;
	}

	protected function __construct() {
		add_filter( 'plugins_url', [ $this, 'plugins_url' ], 10, 3 );
	}

	public function plugins_url( $url, $path, $plugin ) {

		if ( ! empty( $plugin ) && 0 === strpos( $plugin, WP_CONTENT_DIR ) ) {
			$url = WP_CONTENT_URL;
			$plugin = str_replace( WP_CONTENT_DIR, '', $plugin );
			if ( ! empty( $plugin ) && is_string( $plugin ) ) {
				$folder = dirname( plugin_basename( $plugin ) );
				if ( '.' != $folder ) {
					$url .= '/' . ltrim( $folder, '/' );
				}
			}
			if ( $path && is_string( $path ) ) {
				$url .= '/' . ltrim( $path, '/' );
			}
		}

		return $url;
	}

}


Filters::get_instance();
