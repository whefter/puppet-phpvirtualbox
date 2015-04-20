class phpvirtualbox::params
{
    $version                = '4.3-2'
    $base_path              = '/srv/phpvirtualbox'
    
    $httpd                  = false
    $httpd_port             = 80
    $httpd_ssl              = true
    $httpd_ssl_port         = 443
    $httpd_ssl_ca           = undef
    $httpd_ssl_chain        = undef
    $httpd_ssl_crt          = undef
    $httpd_ssl_key          = undef
    $httpd_ssl_protocol     = 'ALL -SSLv2 -SSLv3'
    $httpd_ssl_cipher       = 'EDH+CAMELLIA:EDH+aRSA:EECDH+aRSA+AESGCM:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH:+CAMELLIA256:+AES256:+CAMELLIA128:+AES128:+SSLv3:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!DSS:!RC4:!SEED:!IDEA:!ECDSA:kEDH:CAMELLIA256-SHA:AES256-SHA:CAMELLIA128-SHA:AES128-SHA'
    
    if $httpd {
        include ::apache::params
    }
    
    $www_owner              = $httpd ? {
        true    => $::apache::params::user,
        default => 'root',
    }
    $www_group              = $httpd ? {
        true    => $::apache::params::group,
        default => 'root',
    }
}
