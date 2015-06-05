define phpvirtualbox::instance
(
  $version            = $::phpvirtualbox::version,
  $base_path          = "${::phpvirtualbox::base_path}/${name}",
  $download_proxy     = $::phpvirtualbox::download_proxy,
  $hosts              = {},
  $httpd              = $::phpvirtualbox::httpd,
  $httpd_port         = $::phpvirtualbox::httpd_port,
  $httpd_ssl          = $::phpvirtualbox::httpd_ssl,
  $httpd_ssl_port     = $::phpvirtualbox::httpd_ssl_port,
  $httpd_ssl_ca       = $::phpvirtualbox::httpd_ssl_ca,
  $httpd_ssl_chain    = $::phpvirtualbox::httpd_ssl_chain,
  $httpd_ssl_crt      = $::phpvirtualbox::httpd_ssl_crt,
  $httpd_ssl_key      = $::phpvirtualbox::httpd_ssl_key,
  $httpd_ssl_protocol = $::phpvirtualbox::httpd_ssl_protocol,
  $httpd_ssl_cipher   = $::phpvirtualbox::httpd_ssl_cipher,
  $www_owner          = $::phpvirtualbox::www_owner,
  $www_group          = $::phpvirtualbox::www_group,
  $storeconfigs_tag   = undef
)
{
  include ::phpvirtualbox

  $download_file_basename = "phpvirtualbox-${version}"
  $download_url           = "http://sourceforge.net/projects/phpvirtualbox/files/${download_file_basename}.zip/download"
  $files_path             = "${base_path}/files"
  $download_path          = "${base_path}/download"
  $www_symlink_path       = "${base_path}/www"
  $config_file            = "${base_path}/config.php"
  $download_file          = "${download_path}/${download_file_basename}.zip"
  $version_path           = "${files_path}/${version}"

  exec { "phpvirtualbox_${name}_create_base_path":
    path    => $::path,
    command => "mkdir -p ${base_path}",
    creates => $base_path,
  }

  file { $base_path:
    ensure  => directory,
    owner   => $www_owner,
    group   => $www_group,
    mode    => '0755',
    require => [
      Exec["phpvirtualbox_${name}_create_base_path"],
    ],
  }

  file { $download_path:
    ensure  => directory,
    require => [
      Exec["phpvirtualbox_${name}_create_base_path"],
    ],
  }

  file { $files_path:
    ensure  => directory,
    require => [
      Exec["phpvirtualbox_${name}_create_base_path"],
    ],
  }

  file { $version_path:
    ensure  => directory,
    require => [
      File[$files_path],
    ],
  }

  # Unzip cannot strip components like tar can. The unzip command
  # might (currently does) create a subdirectory in $version_path
  # because phpvirtualbox release ZIP archives contain this folder.
  # Do a bit of shell magic to deal with this.
#  exec { "phpvirtualbox_${name}_download_${version}":
#    path    => $::path,
#    command => "wget ${download_url} -O ${download_file}",
#    creates => "${download_file}",
#    require => [
#      File[$download_path],
#    ],
#  }
#  ~>
#  exec { "phpvirtualbox_${name}_unzip_${version}":
#    path        => $::path,
#    command     => "unzip -o ${download_file} -d ${version_path}",
#    refreshonly => true,
#    require     => [
#      Package['unzip'],
#      File[$version_path],
#    ],
#  }
  
    # Checksum is currently not checked because owncloud's checksum files 
  # do not contain the name of the checked file...
  archive { $download_file_basename:
    ensure           => present,
    url              => $download_url,
    target           => $version_path,
    follow_redirects => true,
    extension        => 'zip',
    src_target       => $download_path,
    checksum         => false,
    digest_type      => 'sha256',
    digest_url       => "${download_url}.sha256",
    proxy_server     => $download_proxy,
    require => [
      File[$version_path],
      File[$download_path],
    ],
  }

  $find_www_cmdline = "$(find \"${version_path}\" -name index.html -print0 | xargs -0 -n1 dirname | head -1)"

  exec { "phpvirtualbox_${name}_chmod_www":
    path        => $::path,
    command     => "chmod 750 ${find_www_cmdline}",
    refreshonly => true,
    subscribe   => [
#      Exec["phpvirtualbox_${name}_unzip_${version}"],
      Archive[$download_file_basename],
    ],
  }

  exec { "phpvirtualbox_${name}_chown_www":
    path        => $::path,
    command     => "chown ${::www_owner}:${::www_group} -R ${find_www_cmdline}",
    refreshonly => true,
    subscribe   => [
#      Exec["phpvirtualbox_${name}_unzip_${version}"],
      Archive[$download_file_basename],
    ],
  }

  exec { "phpvirtualbox_${name}_create_www_symlink":
    path        => $::path,
    command     => "ln -T -f -s ${find_www_cmdline} \"${www_symlink_path}\"",
    unless      => "readlink \"${www_symlink_path}\" | grep ${find_www_cmdline}",
    subscribe   => [
#      Exec["phpvirtualbox_${name}_unzip_${version}"],
      Archive[$download_file_basename],
    ],
  }

  # Configuration file definition, concat definition
  concat_build { "phpvirtualbox_config_${name}":
  }
  ->
  file { $config_file:
    ensure  => file,
    owner   => $www_owner,
    group   => $www_group,
    mode    => '0400',
    source  => concat_output("phpvirtualbox_config_${name}"),
    require => [
      File[$base_path],
    ]
  }

  exec { "phpvirtualbox_${name}_create_config_symlink":
    path      => $::path,
    command   => "ln -f -s \"${$config_file}\" ${find_www_cmdline}/config.php",
    unless    => "readlink ${find_www_cmdline}/config.php | grep \"${config_file}\"",
#    subscribe => [
#      Exec["phpvirtualbox_${name}_unzip_${version}"],
#    ],
    require   => [
      File[$config_file],
      Archive[$download_file_basename],
    ],
  }

  # Header
  concat_fragment { "phpvirtualbox_config_${name}+01":
    content => template('phpvirtualbox/config.php-header.erb'),
  }

  # Servers block
  concat_build { "phpvirtualbox_config_${name}_servers":
    parent_build   => "phpvirtualbox_config_${name}",
    target         => "${::puppet_vardir}/concat_native/fragments/phpvirtualbox_config_${name}/10",
    file_delimiter => ',',
    append_newline => true,
  }

  create_resources(phpvirtualbox::hosts, $hosts, { instance_name => $name })

  # Collect server exported resources
  if $storeconfigs_tag {
    ::Phpvirtualbox::Host <<| tag == $storeconfigs_tag |>>
  }

  # Token content to prevent "no entries for this group" bug
  concat_fragment { "phpvirtualbox_config_${name}_servers+ZZZZ":
    content => '//',
  }

  # Footer
  concat_fragment { "phpvirtualbox_config_${name}+99":
    content => template('phpvirtualbox/config.php-footer.erb'),
  }

  if $httpd {
    # Install and configure Apache
    if !defined(Class['::apache']) {
      class { '::apache':
        mpm_module => 'prefork',
      }
    }

    include ::apache::mod::php

    package { ['php5', 'php-soap']:
      ensure => installed,
    }

    if $httpd_ssl {
      include ::apache::mod::rewrite
      include ::apache::mod::ssl

      ::apache::vhost { "phpvirtualbox-${name}-http":
        port           => $httpd_port,
        docroot        => $www_symlink_path,
        manage_docroot => false,
        rewrites       => [
          {
            comment      => 'Redirect non-SSL traffic to SSL site',
            rewrite_cond => ['%{HTTPS} off'],
            rewrite_rule => ["(.*) https://%{HTTP_HOST}:${httpd_ssl_port}%{REQUEST_URI}]"],
          }
        ],
        require        => [
          Exec["phpvirtualbox_${name}_create_www_symlink"],
        ],
      }

      ::apache::vhost { "phpvirtualbox-${name}-https":
        ssl            => true,
        port           => $httpd_ssl_port,
        ssl_protocol   => $httpd_ssl_protocol,
        ssl_cipher     => $httpd_ssl_cipher,
        ssl_ca         => $httpd_ssl_ca,
        ssl_chain      => $httpd_ssl_chain,
        ssl_cert       => $httpd_ssl_crt,
        ssl_key        => $httpd_ssl_key,
        docroot        => $www_symlink_path,
        manage_docroot => false,
        require        => [
          Exec["phpvirtualbox_${name}_create_www_symlink"],
        ],
      }
    } else {
      ::apache::vhost { "phpvirtualbox-${name}-http":
        port           => $httpd_port,
        docroot        => $www_symlink_path,
        manage_docroot => false,
        require        => [
          Exec["phpvirtualbox_${name}_create_www_symlink"],
        ],
      }
    }
  } 
}