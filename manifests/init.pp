class phpvirtualbox
(
  $version            = $phpvirtualbox::params::version,
  $base_path          = $phpvirtualbox::params::base_path,
  $httpd              = $phpvirtualbox::params::httpd,
  $httpd_port         = $phpvirtualbox::params::httpd_port,
  $httpd_ssl_protocol = $phpvirtualbox::params::httpd_ssl_protocol,
  $httpd_ssl_cipher   = $phpvirtualbox::params::httpd_ssl_cipher,
  $www_owner          = $phpvirtualbox::params::www_owner,
  $www_group          = $phpvirtualbox::params::www_group,
  $instances          = {},
)
inherits phpvirtualbox::params
{

  if !defined(Package['unzip']) {
    package { 'unzip':
    }
  }
  
  create_resources(phpvirtualbox::instance, $instances)
}
