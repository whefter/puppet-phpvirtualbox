define phpvirtualbox::host
(
  $instance_name,
  $host_name,
  $username,
  $password,
  $location,
  $ensure      = present,
  $auth_master = false,
)
{
  $config_servers_block_fragment_file = "/tmp/concat_fragment_phpvirtualbox_config_${instance_name}_servers"

  # phpVirtualBox servers configuration array single server fragment.
  concat_fragment { "phpvirtualbox_config_${instance_name}_servers+${host_name}":
    content => $ensure ? {
      present => template('phpvirtualbox/config.php-server.erb'),
      default => '',
    }
  }
}
