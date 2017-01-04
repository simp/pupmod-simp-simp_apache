# This class configures an Apache server with SSL support.  It ensures that
# the appropriate files are in the appropriate places and have the correct
# permissions.
#
# @NOTE: Any parameter that comes directly from Apache is not documented
# here and should be found in the Apache mod_ssl reference
# documentation.
#
# @param listen
#   An array of ports upon which the stock SSL configuration should
#   listen.
#
# @param trusted_nets
#   An array of networks that you trust to connect to your server.
#
# @param logformat
#   The default LogFormat to be used for SSL logging. Set to '' to
#   disable logging.
#
# @param enable_default_vhost
#   Whether or not to activate the default VirtualHost on the $listen
#   port.
#
# @param firewall
#   Whether or not to use the SIMP iptables module.
#
# @param app_pki_external_source
#   If $pki is :false, this will designate the proper source
#   for the PKI certs to be used by Apache. If neither variable is
#   set, you will need to ensure that certificates are properly
#   uploaded to the system.
#
# @param app_pki_dir
#   The directory of the application certs.
#
# @param pki
#   Whether or not to use to the inbuilt 'pki' module from the SIMP
#   build. This would tie Apache to the system certificates in
#   /etc/pki
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class simp_apache::ssl (
  Array[Simplib::Port]           $listen                  = [443],
  Simplib::Netlist               $trusted_nets            = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1', '::1'] }),
  Array[String]                  $openssl_cipher_suite    = simplib::lookup('simp_options::openssl::cipher_suite', { 'default_value' => ['DEFAULT', '!MEDIUM'] }),
  Array[String]                  $ssl_protocols           = ['TLSv1','TLSv1.1','TLSv1.2'],
  Boolean                        $ssl_honor_cipher_order  = true,
  String                         $sslverifyclient         = 'require',
  Integer                        $sslverifydepth          = 10,
  Stdlib::Absolutepath           $app_pki_external_source = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/simp/pki' }),
  Stdlib::AbsolutePath           $app_pki_dir             = '/etc/httpd/conf',
  Stdlib::AbsolutePath           $app_pki_ca_dir          = "${app_pki_dir}/pki/cacerts",
  Stdlib::AbsolutePath           $app_pki_cert            = "${app_pki_dir}/pki/public/${facts['fqdn']}.pub",
  Stdlib::AbsolutePath           $app_pki_key             = "${app_pki_dir}/pki/private/${facts['fqdn']}.pem",
  String                         $logformat               = '%t %h %{SSL_CLIENT_S_DN_CN}x %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b %s',
  Boolean                        $enable_default_vhost    = true,
  Boolean                        $firewall                = simplib::lookup('simp_options::firewall', { 'default_value' => false, }),
  Boolean                        $haveged                 = simplib::lookup('simp_options::haveged', { 'default_value' => false }),
  Variant[Boolean,Enum['simp']]  $pki                     = simplib::lookup('simp_options::pki', { 'default_value' => false })
) {

  include '::simp_apache'

  if $haveged { include '::haveged' }

  file { '/etc/httpd/conf.d/ssl.conf':
    owner   => pick($::simp_apache::conf::group,'root'),
    group   => pick($::simp_apache::conf::group,'apache'),
    mode    => '0640',
    content => template("${module_name}/etc/httpd/conf.d/ssl.conf.erb"),
    notify  => Service['httpd']
  }

  if $firewall {
    include '::iptables'

    iptables::listen::tcp_stateful { 'allow_https':
      order        => 11,
      trusted_nets => $trusted_nets,
      dports       => $listen
    }
  }

  if $pki {
    ::pki::copy { $app_pki_dir:
      source => $app_pki_external_source,
      group  => pick($::simp_apache::conf::group,'apache'),
      pki    => $pki,
      notify => Service['httpd'],
    }
  }
  else {
    file { "${app_pki_dir}/pki":
      ensure  => 'directory',
      owner   => pick($::simp_apache::conf::group,'root'),
      group   => pick($::simp_apache::conf::group,'apache'),
      mode    => '0640',
      source  => $app_pki_external_source,
      recurse => true,
      notify  => Service['httpd']
    }
  }
}
