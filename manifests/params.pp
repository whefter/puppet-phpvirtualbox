class phpvirtualbox::params
{
  $version            = '4.3-2'
  $base_path          = '/srv/phpvirtualbox'
  $download_proxy     = undef
  $httpd              = false
  $httpd_port         = 80
  $httpd_ssl          = true
  $httpd_ssl_port     = 443
  # /etc/ssl/certs/ssl-cert-snakeoil.pem
  # /etc/ssl/private/ssl-cert-snakeoil.key
  $httpd_ssl_ca       = "${::settings::ssldir}/certs/ca.pem"
  $httpd_ssl_chain    = "${::settings::ssldir}/certs/ca.pem"
  $httpd_ssl_crt      = "${::settings::ssldir}/certs/${::fqdn}.pem"
  $httpd_ssl_key      = "${::settings::ssldir}/private_keys/${::fqdn}.pem"
  $httpd_ssl_protocol = 'ALL -SSLv2 -SSLv3'
  $httpd_ssl_cipher   = 'EDH+CAMELLIA:EDH+aRSA:EECDH+aRSA+AESGCM:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH:+CAMELLIA256:+AES256:+CAMELLIA128:+AES128:+SSLv3:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!DSS:!RC4:!SEED:!IDEA:!ECDSA:kEDH:CAMELLIA256-SHA:AES256-SHA:CAMELLIA128-SHA:AES128-SHA'

  if $httpd {
    include ::apache::params
  }

  $www_owner = $httpd ? {
    true    => $::apache::params::user,
    default => 'root',
  }
  $www_group = $httpd ? {
    true    => $::apache::params::group,
    default => 'root',
  }
}
