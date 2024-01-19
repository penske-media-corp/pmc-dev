<?php
namespace WP\Config;

if ( ! defined( 'IS_UNIT_TEST' ) ) {
	define( 'IS_UNIT_TEST', true );
}

require_once realpath ( __DIR__ . '/bootstrap.php' );

/**
 * This bootsrap tests file is responsible for detecting project environment and various settings
 * support  multiple wp project development in a singled docker instance setup
 */

class Bootstrap_Phpunit extends Bootstrap {

	protected static $_instance = null;
	private $_bootstrap         = false;

	protected function __construct() {

		ifndef( 'WP_BATCACHE', false );

		if ( preg_match( '#^.*/pmc-plugins/#', getcwd(), $matches ) ) {
			ifndef( 'SITE_NAME', 'pmc-plugins' );
			$this->_bootstrap = $matches[0] . 'pmc-unit-test/bootstrap.php';
		}

		parent::__construct();

		if ( empty( $this->_bootstrap ) ) {

			if ( defined( 'IS_VIP_GO' ) && IS_VIP_GO ) {
				if ( ! file_exists( WP_PLUGIN_DIR . '/pmc-plugins/pmc-unit-test/bootstrap.php' ) ) {
					symlink( getenv( 'WEB_ROOT' ) . '/wp-content/themes/vip/pmc-plugins', WP_PLUGIN_DIR . '/pmc-plugins' );
				}
				$this->_bootstrap = WP_PLUGIN_DIR . '/pmc-plugins/pmc-unit-test/bootstrap.php';
			} else {
				$this->_bootstrap = getenv( 'WEB_ROOT' ) . '/wp-content/themes/vip/pmc-plugins/pmc-unit-test/bootstrap.php';
			}

		}

	}

	/**
	 * phpunit test should always active once it is manually referenced
	 */
	public function is_active() {
		return true;
	}

	public function start() {
		if ( empty( $this->_bootstrap ) ) {
			throw new \Error( sprintf('Cannot auto detect pmc plugin bootstrap file location' ) );
		}
		if ( ! file_exists( $this->_bootstrap ) ) {
			throw new \Error( sprintf('Cannot locate bootstrap file: %s', $this->_bootstrap ) );
		}
		require_once $this->_bootstrap;
	}
}

Bootstrap_Phpunit::get_instance()->start();
