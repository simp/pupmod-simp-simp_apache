# @summary Configures an Apache server with SSL support
#
# Ensures that the appropriate files are in the appropriate places and have the
# correct permissions.
#
# @NOTE: Any parameter that comes directly from Apache is not documented
# here and should be found in the Apache mod_ssl reference
# documentation.
#
# @param listen
#   An array of ports upon which the stock SSL configuration should
#   listen.
#
#   @NOTE: If you are using an IPv6 with a port, you need to bracket the
#   address
#
# @param trusted_nets
#   An array of networks that you trust to connect to your server.
#
# @param logformat
#   The default LogFormat to be used for SSL logging. Set to '' to
#   disable logging.
#
# @param enable_default_vhost
#   Whether to activate the default VirtualHost on the $listen port.
#
# @param firewall
#   Whether to use the SIMP iptables module.
#
# @param pki
#   * If 'simp', include SIMP's pki module and use pki::copy to manage
#     application certs in /etc/pki/simp_apps/simp_apache/x509
#   * If true, do *not* include SIMP's pki module, but still use pki::copy
#     to manage certs in /etc/pki/simp_apps/simp_apache/x509
#   * If false, do not include SIMP's pki module and do not use pki::copy
#     to manage certs.  You will need to appropriately assign a subset of:
#     * app_pki_dir
#     * app_pki_key
#     * app_pki_cert
#     * app_pki_ca
#     * app_pki_ca_dir
#
# @param app_pki_external_source
#   * If pki = 'simp' or true, this is the directory from which certs will be
#     copied, via pki::copy.  Defaults to /etc/pki/simp/x509.
#
#   * If pki = false, this variable has no effect.
#
# @param app_pki_dir
#   This variable controls the basepath of $app_pki_key, $app_pki_cert,
#   $app_pki_ca, $app_pki_ca_dir, and $app_pki_crl.
#   It defaults to /etc/pki/simp_apps/simp_apache/pki.
#
# @param app_pki_key
#   Path and name of the private SSL key file
#
# @param app_pki_cert
#   Path and name of the public SSL certificate
#
# @param app_pki_ca_dir
#   Path to the CA.
#
# @param haveged
#   Whether to use the SIMP haveged module to assist with entropy generation.
#
# @see https://httpd.apache.org/docs/current/mod/mod_ssl.html#sslverifyclient
#
# @param openssl_cipher_suite
#   The Cipher Suite the client is permitted to negotiate in the SSL handshake
#   phase.
#
# @param ssl_protocols
#   This directive can be used to control which versions of the SSL/TLS
#   protocol will be accepted in new connections.
#
# @param ssl_honor_cipher_order
#   Option to prefer the server's cipher preference order.
#
# @param sslverifyclient
#   This directive sets the Certificate verification level for the Client
#   Authentication.
#
# @param sslverifydepth
#   This directive sets how deeply mod_ssl should verify before deciding that
#   the clients don't have a valid certificate.
#
# @author https://github.com/simp/pupmod-simp-simp_apache/graphs/contributors
#
class simp_apache::ssl (
  Array[Variant[Simplib::Host::Port, Simplib::Port]] $listen                  = [443],
  Simplib::Netlist                                   $trusted_nets            = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1', '::1'] }),
  Array[String]                                      $openssl_cipher_suite    = simplib::lookup('simp_options::openssl::cipher_suite', { 'default_value' => ['DEFAULT', '!MEDIUM'] }),
  Array[String]                                      $ssl_protocols           = ['TLSv1.2'],
  Boolean                                            $ssl_honor_cipher_order  = true,
  String                                             $sslverifyclient         = 'require',
  Integer                                            $sslverifydepth          = 10,
  Variant[Boolean,Enum['simp']]                      $pki                     = simplib::lookup('simp_options::pki', { 'default_value' => false }),
  String                                             $app_pki_external_source = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki/simp/x509' }),
  Stdlib::AbsolutePath                               $app_pki_dir             = '/etc/pki/simp_apps/simp_apache/x509',
  Stdlib::AbsolutePath                               $app_pki_ca_dir          = "${app_pki_dir}/cacerts",
  Stdlib::AbsolutePath                               $app_pki_cert            = "${app_pki_dir}/public/${facts['networking']['fqdn']}.pub",
  Stdlib::AbsolutePath                               $app_pki_key             = "${app_pki_dir}/private/${facts['networking']['fqdn']}.pem",
  String                                             $logformat               = '%t %h %{SSL_CLIENT_S_DN_CN}x %{SSL_PROTOCOL}x %{SSL_CIPHER}x \"%r\" %b %s',
  Boolean                                            $enable_default_vhost    = true,
  Boolean                                            $firewall                = simplib::lookup('simp_options::firewall', { 'default_value' => false, }),
  Boolean                                            $haveged                 = simplib::lookup('simp_options::haveged', { 'default_value' => false })
) {
  include 'simp_apache'

  if $haveged { include 'haveged' }

  file { '/etc/httpd/conf.d/ssl.conf':
    ensure  => 'file',
    owner   => pick($simp_apache::conf::user,'root'),
    group   => pick($simp_apache::conf::group,'apache'),
    mode    => '0640',
    content => template("${module_name}/etc/httpd/conf.d/ssl.conf.erb"),
    notify  => Class['simp_apache::service']
  }

  if $firewall {
    include 'iptables'

    iptables::listen::tcp_stateful { 'allow_https':
      order        => 11,
      trusted_nets => $trusted_nets,
      dports       => $listen
    }
  }

  if $pki {
    pki::copy { 'simp_apache':
      source => $app_pki_external_source,
      group  => pick($simp_apache::conf::group,'apache'),
      pki    => $pki,
      notify => Class['simp_apache::service']
    }
  }
}
