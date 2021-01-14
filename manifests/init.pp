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
  String               $rsync_source   = "apache_${::environment}_${facts['os']['name']}/www",
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

  $_modules_target = $facts['hardwaremodel'] ? {
    'x86_64' => '/usr/lib64/httpd/modules',
    default  => '/usr/lib/httpd/modules'
  }

  file { $data_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => 'apache',
    mode   => '0640'
  }

  file { '/etc/httpd/conf/magic':
    owner  => 'root',
    group  => 'apache',
    mode   => '0640',
    source => "puppet:///modules/${module_name}/magic",
    notify => Class['simp_apache::service']
  }

  file { '/etc/httpd/conf.d/welcome.conf': ensure => 'absent' }

  file { '/etc/mime.types':
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    notify => Class['simp_apache::service']
  }

  file { '/etc/httpd/logs':
    ensure => 'symlink',
    target => '/var/log/httpd',
    force  => true
  }

  file { '/etc/httpd/modules':
    ensure => 'symlink',
    target =>  $_modules_target,
    force  => true
  }

  file { '/etc/httpd/run':
    ensure => 'symlink',
    target => '/var/run/httpd',
    force  => true,
  }

  file { '/var/log/httpd':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700'
  }

  file { 'httpd_modules':
    ensure => 'directory',
    path   => $_modules_target,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    notify => Class['simp_apache::service']
  }

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
      user     => "apache_rsync_${::environment}_${_downcase_os_name}",
      password => simplib::passgen("apache_rsync_${::environment}_${_downcase_os_name}"),
      source   => $rsync_source,
      target   => '/var',
      server   => $rsync_server,
      timeout  => $rsync_timeout,
      delete   => false
    }
  }

  if $::selinux_current_mode and $::selinux_current_mode != 'disabled' {
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
