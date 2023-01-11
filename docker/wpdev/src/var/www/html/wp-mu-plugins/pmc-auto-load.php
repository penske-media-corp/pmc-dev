<?php
namespace PMC\Mu_Plugin;

/**
 * This plugin is responsible to load any required plugins neccessary for the wp environment
 * eg. post-meta-inspector, rewrite-rules-inspector, etc
 */


class Auto_Load {
	static $_instance = null;

	public static function get_instance() {
		if ( empty( static::$_instance ) ) {
			static::$_instance = new static();
		}
		return static::$_instance;
	}

	protected function __construct() {
		add_action( 'after_setup_theme', [ $this, 'action_after_setup_theme' ], 1 );
		add_action ( 'muplugins_loaded', [ $this, 'action_muplugins_loaded' ] );
	}

	public function action_muplugins_loaded() {
		$plugins = [];

		if ( ! defined( 'AMP__VERSION' ) ) {
			$plugins[] = 'amp';
		}

		$this->load_plugins( $plugins );
	}

	public function action_after_setup_theme() {
		if ( function_exists('pmc_load_plugin') ) {
			pmc_load_plugin( 'post-meta-inspector' );
		}

		$plugins = [];

		if ( ! class_exists( 'WP_Jquery_Update_Test' ) ) {
			$plugins[] = 'wp-jquery-update-test';
		}

		if ( ! class_exists( 'Rewrite_Rules_Inspector' ) ) {
			$plugins[] = 'rewrite-rules-inspector';
		}

		if ( class_exists( \WP\Config\Bootstrap::class ) ) {
			$site_info = \WP\Config\Bootstrap::get_instance()->site_info;
			if ( ! empty( $site_info->plugins ) ) {
				$plugins = array_merge( $plugins, $site_info->plugins );
			}
		}

		$this->load_plugins( $plugins );

	}

	/**
	 * Helper function to auto detect and load the related plugins
	 * @param array $plugins
	 */
	public function load_plugins( array $plugins ) {
		if ( empty( $plugins ) ) {
			return;
		}
		$active_plugins = get_option( 'active_plugins' );
		if ( empty( $active_plugins ) ) {
			$active_plugins = [];
		}

		$count = 0;
		foreach ( $plugins as $plugin ) {
			if ( 'php' === pathinfo( $plugin, PATHINFO_EXTENSION  ) ) {
				$files_to_check = [
					$plugin,
				];
			} else {
				$files_to_check = [
					sprintf('%s/%s.php', $plugin, $plugin ),
					sprintf('%s/plugin.php', $plugin),
				];
			}

			foreach( $files_to_check as $file ) {
				if ( in_array( $file, $active_plugins ) ) {
					break;
				}
				$full_path = sprintf( '%s/%s', WP_PLUGIN_DIR, $file );
				if ( file_exists( $full_path ) ) {
					require_once $full_path;
					$active_plugins[] = $file;
					$count++;
					break;
				}
			}
		}

	}
}

Auto_Load::get_instance();
