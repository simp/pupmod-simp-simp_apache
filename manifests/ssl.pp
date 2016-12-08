# == Class: simp_apache::ssl
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
# [*trusted_nets*]
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
# [*firewall*]
#   Type: Boolean
#   Whether or not to use the SIMP iptables module.
#
# [*cert_source*]
#   Type: Valid File Resource Source
#   If $pki is :false, this will designate the proper source
#   for the PKI certs to be used by Apache. If neither variable is
#   set, you will need to ensure that certificates are properly
#   uploaded to the system.
#
# [*pki*]
#   Type: Boolean
#   Whether or not to use to the inbuilt 'pki' module from the SIMP
#   build. This would tie Apache to the system certificates in
#   /etc/pki
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp_apache::ssl (
  $listen = '443',
  $trusted_nets = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1', '::1'], 'value_type' => Array[String] }),
  $openssl_cipher_suite = simplib::lookup('simp_options::openssl::cipher_suite', { 'default_value' => ['DEFAULT', '!MEDIUM'], 'value_type' => Array[String] }),
  $ssl_protocols = ['TLSv1','TLSv1.1','TLSv1.2'],
  $ssl_honor_cipher_order = 'on',
  $sslverifyclient = 'require',
  $sslverifydepth = '10',
  $sslcacertificatepath = '/etc/httpd/conf/pki/cacerts',
  $sslcertificatefile = "/etc/httpd/conf/pki/public/${::fqdn}.pub",
  $sslcertificatekeyfile = "/etc/httpd/conf/pki/private/${::fqdn}.pem",
  $logformat = '%t %h %{SSL_CLIENT_S_DN_CN}x %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b %s',
  $enable_default_vhost = true,
  $firewall = simplib::lookup('simp_options::firewall',  { 'default_value' => false, 'value_type' => Boolean}),
  $cert_source = '',
  $haveged = simplib::lookup('simp_options::haveged',  { 'default_value' => false, 'value_type' => Boolean}),
  $pki = simplib::lookup('simp_options::pki',  { 'default_value' => false, 'value_type' => Boolean})
) {
  validate_array($openssl_cipher_suite)
  validate_array($ssl_protocols)
  validate_array_member($ssl_honor_cipher_order,['on','off'])
  validate_integer($sslverifydepth)
  validate_absolute_path($sslcacertificatepath)
  validate_absolute_path($sslcertificatefile)
  validate_absolute_path($sslcertificatekeyfile)
  validate_bool($enable_default_vhost)
  validate_bool($firewall)
  validate_bool($pki)
  validate_bool($haveged)

  include '::simp_apache'


  if $haveged {
    include '::haveged'
  }

  file { '/etc/httpd/conf.d/ssl.conf':
    owner   => pick($::simp_apache::conf::group,'root'),
    group   => pick($::simp_apache::conf::group,'apache'),
    mode    => '0640',
    content => template("${module_name}/etc/httpd/conf.d/ssl.conf.erb"),
    notify  => Service['httpd']
  }

  if $firewall {
    include '::iptables'

    iptables::add_tcp_stateful_listen { 'allow_https':
      order        => '11',
      trusted_nets => $trusted_nets,
      dports       => $listen
    }
  }

  if $pki {
    include '::pki'

    ::pki::copy { '/etc/httpd/conf':
      group  => pick($::simp_apache::conf::group,'apache'),
      notify => Service['httpd']
    }
  }
  elsif  !empty($cert_source) {
    file { '/etc/httpd/conf/pki':
      ensure  => 'directory',
      owner   => pick($::simp_apache::conf::group,'root'),
      group   => pick($::simp_apache::conf::group,'apache'),
      mode    => '0640',
      source  => $cert_source,
      recurse => true,
      notify  => Service['httpd']
    }
  }
}
