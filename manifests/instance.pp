define phpvirtualbox::instance
(
    $version                = $::phpvirtualbox::params::version,
    $base_path              = "${::phpvirtualbox::base_path}/${name}",
    $download_file_name     = "phpvirtualbox-${version}.zip",
    $download_url           = "http://sourceforge.net/projects/phpvirtualbox/files/${download_file_name}/download",
    $files_path             = "${base_path}/files",
    $download_path          = "${base_path}/download",
    $download_file          = "${download_path}/${download_file_name}.zip",
    $www_path               = "${files_path}/phpvirtualbox-${version}",
    $www_symlink_path       = "${base_path}/www",
    $config_file            = "${base_path}/config.php",
    
    $httpd                  = $::phpvirtualbox::httpd,
    $httpd_port             = $::phpvirtualbox::httpd_port,
    $httpd_ssl              = $::phpvirtualbox::httpd_ssl,
    $httpd_ssl_protocol     = $::phpvirtualbox::httpd_ssl_protocol,
    $httpd_ssl_cipher       = $::phpvirtualbox::httpd_ssl_cipher,
    $www_owner              = $::phpvirtualbox::www_owner,
    $www_group              = $::phpvirtualbox::www_group,
    
    $hosts                  = {},
)
{
    include ::phpvirtualbox
    
    $config_symlink_file    = "${www_path}/config.php"
    
    # Download and unzip phpVirtualBox
    file { $base_path:
        ensure          => directory,
        owner           => $www_owner,
        group           => $www_group,
        mode            => '0755',
    }
    ->
    file { $download_path:
        ensure          => directory,
    }
    ->
    archive { $download_file_name:
        ensure           => present,
        url              => $download_url,
        follow_redirects => true
        extension        => 'zip'
        target           => $files_path,
        src_target       => '/tmp',
    }
    ->
    file { $www_path:
        ensure          => directory,
        owner           => $www_owner,
        group           => $www_group,
        mode            => '0755',
    }
    ->
    file { $www_symlink_path:
        ensure          => link,
        target          => $www_path,
        force           => true,
    }
    
    # Configuration file definition, concat definition
    concat_build { "phpvirtualbox_config_${name}": }
    ->
    file { $config_path:
        ensure      => file,
        owner       => $www_owner,
        group       => $www_group,
        mode        => '0400',
        source      => concat_output("phpvirtualbox_config_${name}"),
        
        require     => [
            Exec['download and unzip phpvirtualbox'],
        ]
    }
    ->
    file { $config_symlink_path:
        ensure      => link,
        target      => $config_path,
        force       => yes,
    }
    
    # Header
    concat_fragment { "phpvirtualbox_config_${name}+01":
        content     => template('phpvirtualbox/config.php-header.erb'),
    }

    # Servers block
    concat_build { "phpvirtualbox_config_${name}_servers":
        parent_build        => "phpvirtualbox_config_${name}",
        target              => "${::puppet_vardir}/concat_native/fragments/phpvirtualbox_config_${name}/10",
        file_delimiter      => ',',
        append_newline      => true,
    }
    
    create_resources( phpvirtualbox::hosts, $hosts, { instance_name => $name, } )
    
    # Collect server exported resources
    ::Phpvirtualbox::Host <<| tag == $name |>>

    # Token content to prevent "no entries for this group" bug
    concat_fragment { "phpvirtualbox_config_${name}_servers+ZZZZ":
        content     => '//',
    }
    
    # Footer
    concat_fragment { "phpvirtualbox_config_${name}+99":
        content     => template('phpvirtualbox/config.php-footer.erb'),
    }
    
    if $httpd {
        # Install Apache
        include ::apache
        include ::apache::mod::prefork
        include ::apache::mod::php
        
        package { [
                    'php5',
                    'php5-cli',
                    'php5-gd',
                    'php5-curl',
                    'php-pear',
                    'php5-sqlite',
                    'php5-mysql',
                  ]:
            ensure => installed,
        }

        $_httpd_port = $httpd_port ? {
            undef => $httpd_ssl ? {
                true    => 443,
                default => 80,
            },
            default => $httpd_port,
        }
        
        ::apache::vhost { "phpvirtualbox-${name}":
            port            => $_httpd_port,
            ssl             => $httpd_ssl,
            docroot         => $www_symlink_path,
            manage_docroot  => false,
            ssl_protocol    => $httpd_ssl_protocol,
            ssl_cipher      => $httpd_ssl_cipher,
            
            require         => [
                File[$www_symlink_path],
            ],
        }
    }
    
}
