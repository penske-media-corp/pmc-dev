<?php
namespace WP\Config;

if ( ! function_exists( 'ifndef' ) ) {
	if ( file_exists( __DIR__ . '/../wp-functions.php' ) ) {
		require_once( realpath( __DIR__ . '/../wp-functions.php' ) );
	}
}

/**
 * This bootstrap file is responsible for auto create database on demand for each WP site
 */

class Bootstrap {

	protected static $_instance = null;
	protected $_wp_themes_info  = [];
	protected $_domain          = 'pmcdev.local';
	public $site_info           = false;

	public static function get_instance() {
		if ( empty( static::$_instance ) ) {
			static::$_instance = new static();
		}
		return static::$_instance;
	}

	protected function __construct() {

		if ( ! $this->is_active() ) {
			return;
		}

		$this->define_constants();

	}

	/**
	 * Determine if wp configuration bootstrap is active or not
	 * @return bool
	 */
	public function is_active() {
		$use_bootstrap = getenv( 'WP_CONFIG_BOOTSTRAP' );
		return ( ! empty( $use_bootstrap ) && in_array( $use_bootstrap, [ 'true', 'yes' ], true ) );
	}

	public function start() {
		$this->maybe_create_db();
	}

	/**
	 * Helper function to auto create database if not exist avoiding having to manually create each db for multiple project development
	 */
	public function maybe_create_db() {
		$dbh = mysqli_init();
		mysqli_real_connect( $dbh, DB_HOST, DB_USER, DB_PASSWORD );

		if ( ! $dbh ) {
			return;
		}

		$sql = sprintf( 'create database if not exists %s;', DB_NAME );
		mysqli_query( $dbh, $sql );
		mysqli_select_db( $dbh, DB_NAME );

	}

	/**
	 * Responsible to detect and setup various WP constant for VIP Go vs Other configuration
	 */
	public function define_constants() {
		$folder = '';
		$site   = $this->detect_site();

		if ( $site ) {
			if ( defined( 'IS_UNIT_TEST' ) && IS_UNIT_TEST ) {
				unset( $site->db_name );
				unset( $site->hosts );
			}

			if ( ! empty( $site->hosts ) ) {
				if ( empty( $_SERVER['HTTP_HOST'] ) || ! in_array( $_SERVER['HTTP_HOST'], $site->hosts ) ) {
					$_SERVER['HTTP_HOST'] = $_SERVER['SERVER_NAME'] = $site->hosts[0];
				}
			}

			if ( ! empty( $site->db_name ) ) {
				ifdefenv( 'DB_NAME', $site->db_name );
			}

			if ( ! empty( $site->name ) ) {
				ifndef( 'SITE_NAME', $site->name );
			}

			if ( ! empty( $site->hosting_env ) ) {
				switch( $site->hosting_env ) {
					case "other":
						ifdefenv('IS_VIP_GO', false);
						if ( ! empty( $site->WEB_ROOT ) && ! empty( $site->WEB_ROOT ) ) {
							$folder = $site->hosting_env;
						}
						break;
					case "vipgo":
					default:
						ifdefenv('VIP_GO_APP_ENVIRONMENT', true);
						ifdefenv('IS_VIP_GO', true);
						$folder = 'vipgo';
						break;
				}
			}

			if ( ! empty( $_SERVER['HTTP_HOST'] ) ) {
				ifndef( 'WP_HOME', 'https://'. $_SERVER['HTTP_HOST'] );
				ifndef( 'WP_SITEURL', WP_HOME );
			}

		}

		if ( defined( 'DB_NAME' ) ) {
			ifndef( 'AUTH_KEY', DB_NAME );
			ifndef( 'AUTH_SALT', DB_NAME );
			ifndef( 'NONCE_KEY', DB_NAME );
			ifndef( 'NONCE_SALT', DB_NAME );
			ifndef( 'LOGGED_IN_KEY', DB_NAME );
			ifndef( 'LOGGED_IN_SALT', DB_NAME );
			ifndef( 'SECURE_AUTH_KEY', DB_NAME );
			ifndef( 'SECURE_AUTH_SALT', DB_NAME );
		}

		ifdefenv( 'IS_VIP_GO', true );
		if ( IS_VIP_GO ) {
			ifdefenv( 'VIP_GO_ENV', 'dev' );
		}

		if ( IS_VIP_GO ) {
			ifndef( 'PMC_IS_VIP_GO_SITE', true );
			$folder = 'vipgo';
		}

		// if custom folder exists, we want to remap the related plugins folder & url
		if ( ! empty( $folder ) && file_exists( __DIR__ . '/../' . $folder ) ) {
			ifndef( 'WP_PLUGIN_DIR', realpath( __DIR__ . '/../' . $folder ) . '/plugins' );
			ifndef( 'WP_PLUGIN_URL', '/' . $folder . '/plugins' );
			ifndef( 'WPMU_PLUGIN_DIR', realpath( __DIR__ . '/../' . $folder ) . '/mu-plugins' );
			ifndef( 'WPMU_PLUGIN_URL', '/' . $folder . '/mu-plugins' );

			if ( ! file_exists(WPMU_PLUGIN_DIR ) ) {
				mkdir( WPMU_PLUGIN_DIR, 0777, true );
			}
			if ( ! file_exists( realpath( __DIR__ . '/../' . $folder ) . '/mu-plugins/000-auto-includes.php' ) ) {
				symlink( realpath( __DIR__ . '/..' ) . '/wp-mu-plugins/auto-includes.php', realpath( __DIR__ . '/../' . $folder ) . '/mu-plugins/000-auto-includes.php' );
			}
		}

		if ( empty( $GLOBALS['memcached_servers'] ) ) {
			$value = getenv( 'MEMCACHED_SERVER' );
			if ( ! empty( $value ) ) {
				$GLOBALS['memcached_servers'] = [
					'default' => [
						$value,
					],
				];
			}
		}

	}

	/**
	 * Auto detect current site base on available wp themes information
	 * @return array|bool|mixed|object
	 */
	public function detect_site() {
		$this->detect_wp_themes();
		$cwd = getcwd();
		if ( isset( $_SERVER['HTTP_HOST'] ) ) {
			foreach ( $this->_wp_themes_info as $item ) {
				if ( in_array( $_SERVER['HTTP_HOST'], $item->hosts ) ) {
					$this->site_info = $item;
					break;
				}
				if ( $cwd === $item->folder ) {
					$this->site_info = $item;
					break;
				}
			}
		} else {
			$this->site_info = $this->get_folder_info( $cwd );
		}
		return $this->site_info;
	}

	/**
	 * Auto detect all available themes
	 */
	public function detect_wp_themes() {
		$list    = [];
		$web_root = getenv( 'WEB_ROOT' );
		if ( empty( $web_root ) ) {
			$web_root = '/var/www/html';
		}

		if ( file_exists( $web_root . '/wp-content/themes/vip' ) ) {
			$theme_root = realpath( $web_root . '/wp-content/themes/vip' );
		} else {
			$theme_root = realpath( $web_root . '/wp-content/themes' );
		}

		$folders = glob( $theme_root . '/*', GLOB_ONLYDIR );

		foreach ( $folders as $folder ) {

			if ( ! file_exists( $folder . '/style.css' ) ) {
				continue;
			}

			$settings = $this->get_folder_info( realpath( $folder ) );

			if ( in_array( $settings->name, [ 'plugins', 'core', 'core-v2', 'twentyfifteen', 'twentyseventeen', 'twentysixteen' ] ) ) {
				continue;
			}

			$list[ $settings->name ][] = $settings;

		}

		foreach ( $list as $items ) {

			if ( 1 < count( $items ) ) {
				// There is conflict with theme project name, let's try to resolve it by ordering the list
				usort( $items, function( $a, $b ) {
					$score1 = $score2 = 0;

					// Since we're moving towards vipgo env, assign vipgo with a higher score
					if ( in_array( $a->hosting_env, ['vipgo'] ) ) {
						$score1 += 2;
					}
					if ( in_array( $b->hosting_env, ['vipgo'] ) ) {
						$score2 += 2;
					}

					// vipgo vs other?
					if ( $score1 !== $score2 ) {
						return ( $score2 < $score1 ) ? -1 : 1;
					}

					// Fallback to theme name
					return strcmp( $a->theme, $b->theme );
				} );
			}

			foreach ( $items as $item ) {
				if ( ! isset( $item->db_name ) ) {
					$item->db_name = 'wp_' . str_replace( '-', '_', $item->name );
				}
				$this->_wp_themes_info[] = $item;
			}

		}

	}

	/**
	 * Helper function to load and detect theme folder for related information
	 * @param $folder
	 * @return array|mixed|object
	 */
	public function get_folder_info( $folder ) {
		if ( file_exists( $folder . '/.pmc-dev.json' ) ) {
			$settings = json_decode( file_get_contents( $folder . '/.pmc-dev.json' ), false );
			if ( empty( $settings ) ) {
				$settings = (object) [];
			}
		} else {
			$settings = (object) [];
		}

		if ( preg_match( '@/pmc-plugins@', $folder ) ) {
			$settings = (object)[
				'hosts'       => [ 'pmc-plugins.' . $this->_domain ],
				'name'        => 'pmc-plugins',
				'theme'       => false,
			];
		}

		$settings->folder = $folder;
		if ( ! isset( $settings->theme ) ) {
			$settings->theme  = 'vip/' . basename( $folder );
		}

		if ( ! isset( $settings->name ) ) {
			$name           = basename( $folder );
			$name           = str_replace( 'pmc-', '', $name );
			$name           = preg_replace( '/-\d+.*/', '', $name );
			$settings->name = $name;
		}

		if ( empty( $settings->hosts ) ) {
			$settings->hosts = [
				$settings->name . '.' . $this->_domain,
				basename( $settings->theme ) . '.' . $this->_domain,
			];
		} elseif ( ! in_array( basename( $settings->theme ) . '.' . $this->_domain, $settings->hosts ) ) {
			$settings->hosts[] = basename( $settings->theme ) . '.' . $this->_domain;
		}

		if ( empty( $settings->hosting_env ) ) {
			if ( file_exists( $settings->folder . '/docker-compose.yml' ) ) {
				$bufs = file_get_contents( $settings->folder . '/docker-compose.yml' );
				if ( strpos( $bufs, 'vipgo' ) ) {
					$settings->hosting_env = 'vipgo';
				}
			}
			if ( empty( $settings->hosting_env ) ) {
				$settings->hosting_env = false;
			}
		}

		return $settings;

	}

}

Bootstrap::get_instance();
