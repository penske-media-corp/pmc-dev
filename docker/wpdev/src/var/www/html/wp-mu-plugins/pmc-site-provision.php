<?php
namespace PMC\Mu_Plugin;

/**
 * This plugin is responsible to provision a new wp site on demand
 * It will detect the current site and auto create and install the wp core and activate the matching wp theme
 */

// @TODO: need to add default timezone_string to wp options

class Site_Provision {
	private static $_instance = null;
	public static function get_instance() {
		if ( empty( static::$_instance ) ) {
			static::$_instance = new static();
		}
		return static::$_instance;
	}

	protected function __construct() {
		$this->start();
	}

	public function start()
	{
		// We should not do anything if we'rein unit test or CLI mode
		if ( defined( 'IS_UNIT_TEST' )  && IS_UNIT_TEST ) {
			return;
		}
		if ( defined( 'WP_CLI' ) && WP_CLI ) {
			return;
		}

		// WP is being install?
		if ( defined('SITE_NAME') && defined('WP_INSTALLING') && WP_INSTALLING && preg_match( '/install\\.php/', $_SERVER['REQUEST_URI'] ) ) {

			// Force the WP to auto install by pre fill the installation form
			if (!isset($_GET['step'])) {
				$_GET = [
					'step' => 2,
				];
				$_POST = [
					'weblog_title' => SITE_NAME,
					'user_name' => getenv('WP_ADMIN_USER') ?: 'wordpress',
					'admin_password' => getenv('WP_ADMIN_PASS') ?: 'wordpress',
					'admin_password2' => getenv('WP_ADMIN_PASS') ?: 'wordpress',
					'admin_email' => getenv('WP_EMAIL') ?: 'admin@pmcdev.local',
					'blog_public' => 0,
				];
			}

			// We want to trigger our own event during wp install
			add_action('wp_install', [ $this, 'action_wp_install' ]);

			// We don't want disable these events to avoid conflicts
			remove_all_filters( 'muplugins_loaded' );
			remove_all_filters( 'add_option' );

			add_action( 'muplugins_loaded', function() {
				remove_all_filters( 'add_option' );
				remove_all_filters( 'muplugins_loaded' );
			}, 1 );

		}

		add_action( 'muplugins_loaded', [ $this, 'action_muplugins_loaded' ] );

	}

	public function action_wp_install( $user ) {
		$this->maybe_activate_theme();
	}

	public function action_muplugins_loaded() {
		$this->maybe_activate_theme();
	}

	/**
	 * Possible activate theme if needed
	 */
	public function maybe_activate_theme() {

		if ( ! defined( 'SITE_NAME' ) ) {
			return;
		}

		$theme = get_stylesheet();
		if ( preg_match( '@vip/@', $theme ) || preg_match( '@pmc@', $theme ) ) {
			return;
		}

		$prefix = 'vip';
		$items = glob( get_theme_root() . '/' . $prefix . '/*'. SITE_NAME . '*' );
		if ( empty( $items ) ) {
			$prefix = '';
			$items = glob( get_theme_root() . '/*'. SITE_NAME . '*' );
			if ( empty( $items ) ) {
				return;
			}
		}

		$items = array_map( 'basename', $items );
		rsort( $items );
		if ( ! empty( $prefix ) ) {
			$theme = $prefix . '/' . $items[0];
		} else {
			$theme = $items[0];
		}

		// Make sure the theme is valid before we attempt to switch theme
		$theme = wp_get_theme( $theme );
		if ( $theme->exists() && ! $theme->errors() ) {
			switch_theme( $theme->get_stylesheet() );
		}

	}

}

Site_Provision::get_instance();
