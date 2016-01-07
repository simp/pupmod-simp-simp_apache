# == Class: apache::ssl
#
# This class configures an Apache server with SSL support.  It ensures that
# the appropriate files are in the appropriate places and have the correct
# permissions.
#
# == Parameters
#
# NOTE: Any parameter that comes directly from Apache is not documented
# here and should be found in the Apache mod_ssl reference
# documentation.
#
# [*listen*]
#   Type: Array
#   An array of ports upon which the stock SSL configuration should
#   listen.
#
# [*client_nets*]
#   Type: Array
#   An array of networks that you trust to connect to your server.
#
# [*logformat*]
#   The default LogFormat to be used for SSL logging. Set to '' to
#   disable logging.
#
# [*enable_default_vhost*]
#   Type: Boolean
#   Whether or not to activate the default VirtualHost on the $listen
#   port.
#
# [*enable_iptables*]
#   Type: Boolean
#   Whether or not to use the SIMP iptables module.
#
# [*cert_source*]
#   Type: Valid File Resource Source
#   If $use_simp_pki is :false, this will designate the proper source
#   for the PKI certs to be used by Apache. If neither variable is
#   set, you will need to ensure that certificates are properly
#   uploaded to the system.
#
# [*use_simp_pki*]
#   Type: Boolean
#   Whether or not to use to the inbuilt 'pki' module from the SIMP
#   build. This would tie Apache to the system certificates in
#   /etc/pki
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class apache::ssl (
  $listen = '443',
  $client_nets = hiera('client_nets'),
  $ssl_cipher_suite = hiera('openssl::cipher_suite',['HIGH']),
  $ssl_protocols = ['TLSv1','TLSv1.1','TLSv1.2'],
  $ssl_honor_cipher_order = 'on',
  $sslverifyclient = 'require',
  $sslverifydepth = '10',
  $sslcacertificatepath = '/etc/httpd/conf/pki/cacerts',
  $sslcertificatefile = "/etc/httpd/conf/pki/public/${::fqdn}.pub",
  $sslcertificatekeyfile = "/etc/httpd/conf/pki/private/${::fqdn}.pem",
  $logformat = '%t %h %{SSL_CLIENT_S_DN_CN}x %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b %s',
  $enable_default_vhost = true,
  $enable_iptables = true,
  $cert_source = '',
  $use_simp_pki = true
) {
  include '::apache'

  file { '/etc/httpd/conf.d/ssl.conf':
    owner   => hiera('apache::conf::group','root'),
    group   => hiera('apache::conf::group','apache'),
    mode    => '0640',
    content => template('apache/etc/httpd/conf.d/ssl.conf.erb'),
    notify  => Service['httpd']
  }

  if $enable_iptables {
    include '::iptables'

    iptables::add_tcp_stateful_listen { 'allow_https':
      order       => '11',
      client_nets => $client_nets,
      dports      => $listen
    }
  }

  if $use_simp_pki {
    include '::pki'

    ::pki::copy { '/etc/httpd/conf':
      group  => hiera('apache::conf::group','apache'),
      notify => Service['httpd']
    }
  }
  elsif  !empty($cert_source) {
    file { '/etc/httpd/conf/pki':
      ensure => 'directory',
      owner  => hiera('apache::conf::group','root'),
      group  => hiera('apache::conf::group','apache'),
      mode   => '0640',
      source => $cert_source,
      notify => Service['httpd']
    }
  }

  validate_array($ssl_cipher_suite)
  validate_array($ssl_protocols)
  validate_array_member($ssl_honor_cipher_order,['on','off'])
  validate_integer($sslverifydepth)
  validate_absolute_path($sslcacertificatepath)
  validate_absolute_path($sslcertificatefile)
  validate_absolute_path($sslcertificatekeyfile)
  validate_bool($enable_default_vhost)
  validate_bool($enable_iptables)
  validate_bool($use_simp_pki)
}
