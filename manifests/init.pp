# @summary Configures an Apache server
#
# Ensures that the appropriate files are in the appropriate places and can
# optionally rsync the `/var/www/html` content.
#
# Ideally, we will move over to the Puppet Labs apache module in the future but
# it's going to be quite a bit of work to port all of our code.
#
# @param data_dir
#   The location where apache web data should be stored. Set to /srv/www for
#   legacy reasons.
#
# @param rsync_web_root
#   Whether or not to rsync over the web root.
#
# @param ssl
#   Whether or not to enable SSL. You will need to set the Hiera
#   variables for apache::ssl appropriately for your needs.
#
# @param rsync_source
#  The source on the rsync server.
#
# @param rsync_server
#  The name/address of the rsync server.
#
# @param rsync_timeout
#  The rsync connection timeout.
#
# @author https://github.com/simp/pupmod-simp-simp_apache/graphs/contributors
#
class simp_apache (
  Stdlib::AbsolutePath $data_dir       = '/var/www',
  Boolean              $ssl            = true,
  String               $rsync_source   = "apache_${facts['environment']}_${facts['os']['name']}/www",
  Simplib::Host        $rsync_server   = simplib::lookup('simp_options::rsync::server',  { 'default_value' => '127.0.0.1' }),
  Integer              $rsync_timeout  = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => 2 }),
  Boolean              $rsync_web_root = true
) {

  simplib::assert_metadata($module_name)

  include 'simp_apache::install'
  include 'simp_apache::conf'
  include 'simp_apache::service'

  if $ssl {
    include 'simp_apache::ssl'
    Class['simp_apache::install'] -> Class['simp_apache::ssl']
  }

  Class['simp_apache::install'] -> Class['simp_apache']
  Class['simp_apache::install'] -> Class['simp_apache::conf']
  Class['simp_apache::install'] ~> Class['simp_apache::service']
  Class['simp_apache::conf']    ~> Class['simp_apache::service']

  $apache_homedir = '/usr/share/httpd'

  group { 'apache':
    ensure    => 'present',
    allowdupe => false,
    gid       => '48'
  }

  if $rsync_web_root {
    include 'rsync'

    # Rsync the /var/www space from the rsync server.
    # Add anything here you want to go to every web server.
    $_downcase_os_name = downcase($facts['os']['name'])
    rsync { 'site':
      user     => "apache_rsync_${facts['environment']}_${_downcase_os_name}",
      password => simplib::passgen("apache_rsync_${facts['environment']}_${_downcase_os_name}"),
      source   => $rsync_source,
      target   => '/var',
      server   => $rsync_server,
      timeout  => $rsync_timeout,
      delete   => false
    }
  }

  if $facts['os']['selinux']['current_mode'] and $facts['os']['selinux']['current_mode'] != 'disabled' {
    selboolean { [
      'httpd_verify_dns',
      'allow_ypbind',
      'allow_httpd_mod_auth_pam',
      'httpd_can_network_connect'
    ]:
      persistent => true,
      value      => 'on'
    }
  }

  user { 'apache':
    ensure     => 'present',
    allowdupe  => false,
    gid        => '48',
    home       => $apache_homedir,
    membership => 'minimum',
    shell      => '/sbin/nologin',
    uid        => '48',
    require    => Group['apache']
  }
}
